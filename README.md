# PGPYML - Deploy your Machine Learning Models on Postgres

[![PGXN version](https://badge.fury.io/pg/pgpyml.svg)](https://badge.fury.io/pg/pgpyml) [![License](https://img.shields.io/badge/license-PostgreSQL-informational)](https://img.shields.io/badge/license-PostgreSQL-informational) [![Issues](https://img.shields.io/github/issues/Minoro/pgpyml)](https://github.com/Minoro/pgpyml/issues)


[![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/) [![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/) [![scikit-learn](https://img.shields.io/badge/scikit--learn-%23F7931E.svg?style=for-the-badge&logo=scikit-learn&logoColor=white)](https://scikit-learn.org)

This repository contains an Postgres extension that allows you to run your machine learning algorithms written in python and invoke them on Postgres. This way you can write your script in the way you are used to, and apply it right on your data. You can train and save your `sklearn` models and call then with the data stored on Postgres.

You can read more in the [Documentation](https://minoro.github.io/pgpyml/).

# Work In Progress (WIP)

This extension is not production-ready, but can be used to build a machine learning or data science MVP. You may work on a team with data scientists and fullstack developers, with pgpyml the data scientists can focus on the data while the "fullstackers" can focus on the presentation of the MVP. 

**Contributions and suggestions are welcome**.


# Install

You can install the extension using the **pgnxclient**:

```shell
pgxn install pgpyml
```

And create the extension on your database:
```sql
-- Create a new schema
CREATE SCHEMA IF NOT EXISTS pgpyml
-- Create the extension on pgpyml schema
CREATE EXTENSION pgpyml SCHEMA pgpyml CASCADE;
```


This extension uses the plpython3u, so make sure this extension is installed. You can read more about it on the [documentation](https://minoro.github.io/pgpyml/get-started/#install).

# Save your python sklearn model

After training your model, you can save it using `joblib`:
```python
from sklearn.tree import DecisionTreeClassifier
from joblib import dump, load
    
# some code to load your data...

model = DecisionTreeClassifier()

model.fit(X_train, y_train)
dump(model, './iris_decision_tree.joblib')
```

Once your model are ready, you can use it right on your data stored on Postgres.

# Using the model

You can use the `predict` function to apply the trained model on your stored data.
```sql
-- Notice that the features are passed as a nested array
SELECT * FROM pgpyml.predict('/home/vagrant/examples/iris/models/iris_decision_tree.joblib', '{{5.2,3.5,1.5,0.2}}');
-- Output: {Iris-setosa} (or any other class your model predict)

-- You can pass many features at once
SELECT * FROM pgpyml.predict('/home/vagrant/examples/iris/models/iris_decision_tree.joblib', '{{5.2,3.5,1.5,0.2}, {7.7,2.8,6.7,2.0}}');
-- Output: {Iris-setosa,Iris-virginica}

-- You can also use the ARRAY notation
SELECT * FROM pgpyml.predict('/home/vagrant/examples/iris/models/iris_decision_tree.joblib', ARRAY[[5.2,3.5,1.5, 0.2], [7.7,2.8,6.7,2.0]]);
-- Output: {Iris-setosa,Iris-virginica}
```
The first argument is the path to your trained model, this path must be reachable by your Postgres server. The second argument is a list of features array, each element of the list will have an element on the output. The output are an text array with the predictions of your model.

You can also create a trigger to classify new data inserted on the table. You may use the function `classification_trigger` to help you create a trigger that use your trained model to classify your new data:
```sql
CREATE TABLE iris (
	id SERIAL PRIMARY KEY,
	sepal_length float,
	sepal_width float,
	petal_length float,
	petal_width float,
	class VARCHAR(20) -- column where the prediction will be saved
);

CREATE TRIGGER classify_iris
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE pgpyml.classification_trigger(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', -- Model path
	'class', -- Column name to save the result
	'sepal_length', -- Feature 1
	'sepal_width', -- Feature 2
	'petal_length', -- Feature 3
	'petal_width'-- Feature 4
);
```

The first argument of `classification_trigger` function is the path to your trained model, the second one is the column name where you want to save the prediction of your model (must exists in the same table where your trigger is acting), and any other parameter passed after the second argument will be used as a column name where the feature data are stored.

After creating the trigger you can insert new data on the table, and the result of the classification will be saved on the column specified in the second argument:

```sql
-- Notice that the class is not being inserted, but will be added by the trigger function
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- Check the last inserted row, it will have the column 'class' filled
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```

Besides that you can also apply your model in the data that are already stored in your database. To do that you can use the `predict_table_row` function. This function expects as the first argument the model you want to use, the second argument is the name of the table where the data is stored, the third argument is an array with the name of the columns that will be used as features by your model, and finally the forth argument is the id of the row you want to classify: 

```sql
SELECT * FROM pgpyml.predict_table_row(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', -- The trained model
	'iris', -- Table with the data
	'{"sepal_length", "sepal_width", "petal_length", "petal_width"}', -- The columns used as feature
	1 -- The ID of your data
);
```
## Aborting insertions based on the predictions

Sometimes you may want to avoid the insertion of some items that belongs to a specific class, like transactions identified as fraudulent, to this purpose you can use `trigger_abort_if_prediction_is` function to create a trigger to cancel the insertion of the undesired class:

```sql
CREATE TRIGGER abort_if_iris_setosa
BEFORE INSERT ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE pgpyml.trigger_abort_if_prediction_is(
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

The first argument of the function `trigger_abort_if_prediction_is` is the path to the model to be used, the second one is the class that should be avoided, it will cancel the insertion if the prediction is equals to this class. Any other argument will be used as colunms name to get the values to be predicted.

In the same way, you may want to avoid insertions unless the row belongs to a specific class (e.g. only accept transactions classified as "trustful"). The function `trigger_abort_unless_prediction_is` can help you to achieve that, it will cancel the insertion unless the predicted class belongs to the specified class:

```sql
-- Drop the other trigger if you have created it.
-- DROP TRIGGER abort_if_iris_setosa ON iris;

CREATE TRIGGER abort_unless_is_iris_setosa
BEFORE INSERT ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE pgpyml.trigger_abort_unless_prediction_is(
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
EXECUTE PROCEDURE pgpyml.trigger_classification_or_abort_unless_prediction_is(
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

The `trigger_classification_or_abort_if_prediction_is` and `trigger_classification_or_abort_unless_prediction_is` accept the same paremeters, the first one is the path to the model that will do the predictions, the second one the name of the column that will store the prediction, the thrid value is the prediction expected, and the others parameters will be used as columns name to get the values used in the prediction.

# Getting Deeper
You can read more about this extension and see other functions on the [Official Documentation](https://minoro.github.io/pgpyml)

# Vagrant
If you want to test this extension you can use the vagrant configuration inside the directory `vagrant/Vagrantfile`, this machine use Ubuntu, has a Postgres 14 installed and map the default port `5432` to `5555` in the host machine. This respository will be maped inside `/home/vagrant/examples/` directory. To use this vagrant machine. inside `vagrant` directory, run:
```shell
vagrant up	# Initiate the machine
vagrant ssh # Acess the machine
```
Now you can connect to Postgresql on host `http://localhost:5555` through your host machine.

# License

Copyright (c) 2021, André Minoro Fusioka.

This module is free software; you can redistribute it and/or modify it under the [PostgreSQL License](http://www.opensource.org/licenses/postgresql).

Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without a written agreement is hereby granted, provided that the above copyright notice and this paragraph and the following two paragraphs appear in all copies.

IN NO EVENT SHALL André Minoro Fusioka BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF André Minoro Fusioka HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

André Minoro Fusioka SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND André Minoro Fusioka HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.