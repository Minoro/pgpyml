# pgpyml - Postgres running your python machine learning model

This repository contains an Postgres extension that allows you to run your machine learning algorithms writen in python in Postgres. This way you can write your script in the way you are used to, and apply it right on your data. You can train and save your `skelearn` models and call then with the data stored on Postgres.

# Install

This extension uses the plpython3u, so make sure this extension is installed and created:
```
apt install postgresql-plpython3-12
```

Then on Postgres:

```sql
CREATE EXTENSION plpython3u;
```

Then clone this repository and run:
```
make install
```

And finally create the extension on your database:
```sql
CREATE EXTENSION pgpyml;
```

# Save your python sklearn model

After training your model, you can save it using `joblib`:
```python
from sklearn.tree import DecisionTreeClassifier
from joblib import dump, load

# some code... 

model = DecisionTreeClassifier()

model.fit(X_train, y_train)
dump(model, '/home/vagrant/vagrant_data/saved_models/decision_tree.joblib')
```

If you want to see a full example, this repository has and example using the [UCI Iris Dataset](https://archive.ics.uci.edu/ml/datasets/Iris/). The data are splited in two CSV files inside `dataset/sample_data` folder, one you can use to train and test your model  and the other you may use to simulate a new data to insert on your database. The script `scr/mode/train.py` has a full example how to train and save your model using this dataset.

Once your model are ready, you can use it right on your data stored on Postgres.

# Using the model

You can use the `predict` function to apply the trained model on your stored data.
```sql
SELECT * FROM predict('/home/vagrant/vagrant_data/saved_models/decision_tree.joblib', '{5.2,3.5,1.5,0.2}');

-- Output: Iris-setosa (or any other class your model predict)
```
The first argument is the path to your trained model, this path must be reachable by your Postgres server. The second argument is the feature array, in this exeample are the values to be classifed.

You can also create a trigger to classify new data inserted on the table. You may use the function `classification_trigger` to help you create a trigger that use your trained model to classify your new data:
```sql
CREATE TRIGGER classify_iris
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE classification_trigger(
	'/home/vagrant/vagrant_data/saved_models/decision_tree.joblib', -- Model path
	'class', -- Column name to save the result
	'sepal_length', -- Feature 1
	'sepal_width',  -- Feature 2
	'petal_length', -- Feature 3
	'petal_width'   -- Feature 4
);
```

The first argument of `classification_trigger` function is the path to your trained model, the second argument is the column name where you want to save the prediction of your model (must exists in the same table where your trigger is acting), and any other parameter passed after the second argument will be used as a column name where the feature data are stored.

After creating the trigger you can insert new data on the table, and the result of the classification will be saved on the column specified in the second argument:

```sql
-- Notice that the class is not being inserted, but will be added by the trigger function
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);

-- Check the last inserted row
SELECT * FROM iris WHERE id = (SELECT MAX(id) FROM iris);
```



# Vagrant
If you want to test this extension you can use the vagrant configuration inside the directory `vagrant/Vagrantfile`, this machine use Ubuntu, has a Postgres 12 installed and map the default port `5432` to `5555` in the host machine. This respository will be maped inside `/home/vagrant/vagrant_data/` directory. To use this vagrant machine. inside `vagrant` directory, run:
```
vagrant up	# Initiate the machine
vagrant ssh # Acess the machine
```

