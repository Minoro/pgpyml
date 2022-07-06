-- Create a new database
-- CREATE DATABASE machine_learning;

-- Create the extesion
-- CREATE EXTENSION plpython3u;
-- CREATE EXTENSION pgpyml;

-- Create the basic table
CREATE TABLE iris (
	id SERIAL PRIMARY KEY,
	sepal_length float,
	sepal_width float,
	petal_length float,
	petal_width float,
	class VARCHAR(20)
);

-- When your model is ready you can create a trigger to classify the data you are storing in your database
-- You can use the function classification_trigger to create a classification trigger.
-- The first argument is the path to your model. The second one is the column where the classification result will be stored.
-- Any argument after the second one will be used as a feature column that will feed your model.

-- Drop trigger if it exists
-- DROP TRIGGER IF EXISTS classify_iris ON iris;

CREATE TRIGGER classify_iris
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE classification_trigger(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
	'class',
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);


-- If you want to avoid the insertion of a specific class you can use the following trigger

-- Drop trigger if it exists
-- DROP TRIGGER IF EXISTS abor_if_iris_setosa ON iris;

CREATE TRIGGER abor_if_iris_setosa
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE trigger_abort_if_prediction_is(
	'/home/vagrant/examples/iris/models/iris_decision_tree.joblib', 
	'Iris-setosa', -- avoid the insertion of iris-setosa
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);

-- Test the trigger with some data
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.3,2.5,4.9,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.7,3.2,1.3,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.8,3.2,5.9,2.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (7.7,2.6,6.9,2.3);

