# PGPYML

Python is a popular language to develop machine learning solutions. You may use this language to do some exploratory data analysis and write a model to do predictions over new data to your users. When you are satisfied with the results produced by your model you will deploy it, but this task can be time-consuming. With `pgpyml` you can easly use your model as an in-database solution and take the [advantages of this approach](https://blogs.oracle.com/bigdata/post/why-you-should-use-your-database-for-machine-learning).

Pgpyml is an extension that allows you to use your models written in Python inside PostgreSQL. You can make predictions directly on the data being inserted at your base, you can also create triggers to avoid insertions based on the predictions.

This extension is under development, designed to be compatible with `sklearn` and is not ready to be used in the production environment.

# Table of Contents

- [PGPYML](#pgpyml)
- [Table of Contents](#table-of-contents)
- [Instalation](#instalation)
	- [Prerequisites](#prerequisites)
	- [Install with Git](#install-with-git)
	- [Install with PGNXClient](#install-with-pgnxclient)
	- [Creating the Extension](#creating-the-extension)
- [Using the Vagrant Machine](#using-the-vagrant-machine)
- [How to use](#how-to-use)
	- [Predict](#predict)
		- [Example](#example)
	- [Predicting stored data](#predicting-stored-data)
		- [Example](#example-1)
	- [Predicting on new data](#predicting-on-new-data)
		- [Example](#example-2)
	- [Aborting insertions based on the predictions](#aborting-insertions-based-on-the-predictions)
		- [Example](#example-3)
	- [Allowing insertions based on predictions](#allowing-insertions-based-on-predictions)
		- [Example](#example-4)
	- [Predicting and inserting or aborting insertions](#predicting-and-inserting-or-aborting-insertions)

# Instalation

This section will instruct you how to install the `pgpyml` extension. You must follow the [Prerequisites](#rerequisites) section and chose the [git installation instructions](#install-with-git) or the [pgxnclient instructions](#install-with-pgnxclient). Once you the installation is done you can [create the extension](#creating-the-extension) on you database.

## Prerequisites

First of all, you will need to install the python libraries that are used to write and run your machine learning models:
```
pip3 install numpy scikit-learn pandas
```

This command you install the `numpy`, `sklearn` and `pandas` libraries. The `pgpyml` extension expects that you use `sklearn` to build your models.

You will need to install the python extension to PostgreSQL. You can do this with the command:
```
# Replace the <version> with your postgres version
apt -y install postgresql-plpython3-<version>
```

Replace the `<version>` in the command with the Postgres version that you are using, for example, if you want to install the python extension to Postgres 14 use:
```
apt -y install postgresql-plpython3-14
```

## Install with PGNXClient

Alternatively you can install the extension using the `pgnxclient`, you will need to install it if you don't already have it:

```
apt install pgxnclient
```

And then you can install the `pgpyml` extension with:
```
pgxn install pgpyml
```


## Install with Git

You can install the `pgpyml` with git, cloning the repository and running the instalation script. To do this, first clone the extension's repository:

```
git clone -b v0.1.0 https://github.com/Minoro/pgpyml.git
```

Change the `v0.1.0` to the [desired version](https://github.com/Minoro/pgpyml/tags). And inside the downloaded folder run the make file:
```
make install
make clean
```

This should install the extension and make it available to be used in the Postgres.

## Creating the Extension

After you have installed the extension you can create it on your database. To do this, you need to connect to the desired database and create the python extension and the `pgpyml`:

```sql
-- Python Language extension
CREATE EXTENSION plpython3u;

-- The pgpyml extension
CREATE EXTENSION pgpyml;
```

Now you are ready to use your machine learning model inside your database.


# Using the Vagrant Machine

The `pgpyml` repository has a [Vagrantfile](https://github.com/Minoro/pgpyml/blob/main/vagrant/Vagrantfile) that you can use to test this extension, the repository also include an example of how you can train and save a model. The example use the [UCI Iris Dataset](https://archive.ics.uci.edu/ml/datasets/Iris/), with are also included in the repository.

To use the vagrant machine you can navigate to the `vagrant` folder and run:
```
vagrant up	# Initiate the machine
vagrant ssh # Acess the machine
```

After that you will be able to connect to Postgresql on host `http://localhost:5555` through your host machine.

Although it is not necessary to use the vagrant file from the extension repository, the examples will be displayed using the paths of the virtual machine.

# How to use

We will use the [UCI Iris Dataset](https://archive.ics.uci.edu/ml/datasets/Iris/) as example. We will split the data and use [70% of it as training samples](https://github.com/Minoro/pgpyml/blob/main/examples/iris/dataset/iris_70.data) and [30% to simulate new data](https://github.com/Minoro/pgpyml/blob/main/examples/iris/dataset/iris_30.data). You should keep in mind that in this example the [iris_70]((https://github.com/Minoro/pgpyml/blob/main/examples/iris/dataset/iris_70.data)) represents the data you have to train your model, so you should splitting it to train and test your model, while the [iris_30](https://github.com/Minoro/pgpyml/blob/main/examples/iris/dataset/iris_30.data) we will be used to simulate new data beeing inserted on the database. Feel free to change this split ratio as you want.

You can train your python model with sklean and [save it with joblib](https://scikit-learn.org/stable/modules/model_persistence.html). You can use the [repository script](https://github.com/Minoro/pgpyml/blob/main/examples/iris/models/train_iris_decision_tree.py) as example, but the core concept is:

```python
from sklearn.tree import DecisionTreeClassifier
from joblib import dump, load

# some code to load your data...

# create the model
model = DecisionTreeClassifier()

# train your model
model.fit(X_train, y_train)

# some code to evaluate your model...

# Save the trained model
dump(model, './iris_decision_tree.joblib')
```

Alternativaly you can use the [available model](https://github.com/Minoro/pgpyml/blob/main/examples/iris/models/iris_decision_tree.joblib) inside the repository.

You will also need to create an table to store your data: 

```sql
CREATE TABLE iris (
	id SERIAL PRIMARY KEY,
	sepal_length float,
	sepal_width float,
	petal_length float,
	petal_width float,
	class VARCHAR(20) -- column where the prediction will be saved
);

-- Populate the table with the data used in the training process
COPY iris(sepal_length, sepal_width, petal_length, petal_width, class)
FROM '/home/vagrant/examples/iris/dataset/iris_70.data'
DELIMITER ',';
```


## Predict

After you trained your model you can use it inside postgres to predict new data. The function `predict` will load your model and apply it over the informed data. The `predict` function expects the trained model and the features to be classified. 

The **first argument** is the path to your trained model, this path must be reachable by your Postgres server. The **second argument** is a list of features array, each element of the list will have an element on the output. The **output are an text** array with the predictions of your model.

``` sql
predict(
    model_path text, -- Path to the trained model
    input_values real[] -- Features to be classified
)
```

### Example

```sql
{% raw  %}
-- Notice that the features are passed as a nested array
SELECT * FROM predict(
    '/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
    '{{5.2,3.5,1.5,0.2}}'
);
-- Output: {Iris-setosa} (or any other class your model predict)

-- You can pass many features at once
SELECT * FROM predict(
    '/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
    '{{5.2,3.5,1.5,0.2}, {7.7,2.8,6.7,2.0}}'
);
-- Output: {Iris-setosa,Iris-virginica}
{% endraw %}
```

There are also the function `predict_int` and `predict_real` that will cast the output to `INT` and `REAL` respectively. When you do a prediction the model will be loaded to the memory. If can also load it manually, read the [Loading the Model](io/README.md) section


## Predicting stored data

Besides that you can also apply your model in the data that are already stored in your database. To do that you can use the `predict_table_row` function.

This function expects as the **first argument** the model you want to use, the **second argument** is the name of the table where the data is stored, the **third argument** is an array with the name of the columns that will be used as features by your model, and finally the **forth argument** is the id of the row you want to classify.

```sql
predict_table_row(
    model_path text, -- Path to the trained model 
    table_name text,  -- Name of the table where the data are stored
    columns_name text[],  -- Array with the name of the columns that holds the features values
    id int -- ID of the row that will be predicted
)
```

### Example

```sql
{% raw %}
SELECT * FROM predict_table_row(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', -- The trained model
	'iris', -- Table with the data
	'{"sepal_length", "sepal_width", "petal_length", "petal_width"}', -- The columns used as features
	1 -- The ID of your data
);
{% endraw %}
```

## Predicting on new data

While it is interesting to use your models over stored data, it is likely that applying the models over new data entered by users is a more interesting feature. You can create a trigger to predict the data being stored by the user, to help you there are the `classification_trigger` function.

The function `classification_trigger` will create a trigger to classify the new data and store the prediction in the specified column on the table. 

The **first argument** of `classification_trigger` function is the path to your trained model, the **second** one is the column name where you want to save the prediction of your model (must exists in the same table where your trigger is acting), and **any other parameter** passed after the second argument will be used as a column name where the feature data are stored.

```sql
classification_trigger(
	model_path text, -- Model path
	column_where_the_prediction_will_be_saved text, -- Column name to save the result
	column_name_1 text, -- Feature 1
	column_name_2 text, -- Feature 2
	..., -- more features
    column_name_n text, -- Feature n

) RETURNS trigger;
```

### Example

```sql
CREATE TRIGGER classify_iris
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE classification_trigger(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', -- Model path
	'class', -- Column name to save the result
	'sepal_length', -- Feature 1
	'sepal_width', -- Feature 2
	'petal_length', -- Feature 3
	'petal_width'-- Feature 4
);
```
After creating the trigger you can insert new data on the table, and the result of the classification will be saved on the column specified in the second argument:

```sql
-- Notice that the class is not being inserted, but will be added by the trigger function
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- Check the last inserted row, it will have the column 'class' filled
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

## Aborting insertions based on the predictions

Sometimes you may want to avoid the insertion of some items that belongs to a specific class, like transactions identified as fraudulent, to this purpose you can use `trigger_abort_if_prediction_is` function to create a trigger to cancel the insertion of the undesired class.

The **first argument** of the function `trigger_abort_if_prediction_is` is the path to the model to be used, the **second** one is the class that should be avoided, it will cancel the insertion if the prediction is equals to this class. **Any other argument** will be used as colunms name to get the values to be predicted.

```sql
trigger_abort_if_prediction_is(
	model_path text, -- Model path
	prediction_value_to_avoid mixed, -- Value to abort the transaction
	column_name_1 text, -- Feature 1
	column_name_2 text, -- Feature 2
	..., -- more features
    column_name_n text, -- Feature n

) RETURNS trigger;
```

### Example

```sql
CREATE TRIGGER abort_if_iris_setosa
BEFORE INSERT ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE trigger_abort_if_prediction_is(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
	'Iris-setosa', -- avoid the insertion of Iris-setosa
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);

-- Insert a Iris-versicolor
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.0,2.2,5.0,1.5);

-- Try to insert a Iris-setosa, but will raise an exception
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- Show the last inserted row, that should be the Iris-versicolor
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

## Allowing insertions based on predictions

In the same way, you may want to avoid insertions unless the row belongs to a specific class (e.g. only accept transactions classified as "trustful"). The function `trigger_abort_unless_prediction_is` can help you to achieve that, it will cancel the insertion unless the predicted class belongs to the specified class.

The **first argument** of the function `trigger_abort_unless_prediction_is` is the path to the model to be used, the **second** one is the class that is allowed to be inserted, any other class predicted will cancel the insertion. **Any other argument** will be used as colunms name to get the values to be predicted. The function signature are similiar to `trigger_abort_if_prediction_is`, but only predictions that match the second paremeter will be allowed.

```sql
trigger_abort_if_prediction_is(
	model_path text, -- Model path
	prediction_value_allowed mixed, -- Value that is allowed
	column_name_1 text, -- Feature 1
	column_name_2 text, -- Feature 2
	..., -- more feature
    column_name_n text, -- Feature n

) RETURNS trigger;
```

### Example

```sql
-- Drop the other trigger if you have created it.
-- DROP TRIGGER abort_if_iris_setosa ON iris;

CREATE TRIGGER abort_unless_is_iris_setosa
BEFORE INSERT ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE trigger_abort_unless_prediction_is(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
	'Iris-setosa', -- only accept insertion if the prediction match this value
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);

-- Insert a new row (Iris-setosa) 
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- Try to insert a new row (Iris-versicolor), buit will raise an exception
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.0,2.2,5.0,1.5);

-- Show the last inserted row, that should be the Iris-setosa
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

## Predicting and inserting or aborting insertions

If you are following the examples you will notice that the `class` column is allways been filled, but the functions `trigger_abort_if_prediction_is` and `trigger_abort_unless_prediction_is` do not fill that column, the triggers generated by this functions only abort the insertion. The classification is been done by the `classify_iris` tigger, generated by `classification_trigger` function. If you drop this trigger and try to insert a new row, you will notice that the `class` column is `NULL`:

```sql
-- Drop the classification triger
DROP TRIGGER classify_iris ON iris;

-- If the 'abort_unless_is_iris_setosa' trigger still acting on the table you can insert a new Iris-setosa
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- You will notice that the new row was inserted, but the `class` column is NULL
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

The `trigger_abort_*` function are designed only to cancel operations, but some times can be useful to save the prediction if the operations succeeds. You can do that using this functions in combination with `classification_trigger`, but the `pgpyml` extension offers you functions to generate trigger that do both actions at once, this way you can create a single trigger to avoid undesired insertions and save the classification if it succeeds. To do that you can use the functions `trigger_classification_or_abort_if_prediction_is` and `trigger_classification_or_abort_unless_prediction_is`:

```sql
-- Drop the trigger if needed
-- DROP TRIGGER abort_unless_is_iris_setosa ON iris;

-- Create a new trigger to classify the data or abort if needed
CREATE TRIGGER abort_unless_is_iris_setosa
BEFORE INSERT ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE trigger_classification_or_abort_unless_prediction_is(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
	'class', -- column where the prediction will be stored
	'Iris-setosa', -- avoid the insertion of iris-setosa
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);

-- If you try to insert a Iris-versicolor it will fail
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.0,2.2,5.0,1.5);

-- Insert an Iris-setosa
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- The 'class' column will be filled
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

The `trigger_classification_or_abort_if_prediction_is` and `trigger_classification_or_abort_unless_prediction_is` accept the same paremeters, **the first** one is the path to the model that will do the predictions, **the second** one the name of the column that will store the prediction, **the thrid** value is the prediction expected, and the **others parameters** will be used as columns name to get the values used in the prediction.