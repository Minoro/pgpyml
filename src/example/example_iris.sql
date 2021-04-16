-- Create the basic table
CREATE TABLE iris (
	id SERIAL PRIMARY KEY,
	sepal_length float,
	sepal_width float,
	petal_length float,
	petal_width float,
	class VARCHAR(20)
);
*/


-- Load some samples used for traing
COPY iris(sepal_length, sepal_width, petal_length, petal_width, class)
FROM '/home/vagrant/vagrant_data/dataset/sample_data/iris_70.data'
DELIMITER ',';


-- Create a function to classify the data
CREATE OR REPLACE FUNCTION classify_iris() RETURNS trigger AS
$$

sepal_length = TD['new']['sepal_length']
sepal_width = TD['new']['sepal_width']
petal_length = TD['new']['petal_length']
petal_width = TD['new']['petal_width']
features = [[sepal_length, sepal_width, petal_length, petal_width]]

stmt = plpy.prepare("SELECT predict('/home/vagrant/vagrant_data/dataset/saved_models/decision_tree.joblib', $1)", ['real[]'])
results =  plpy.execute(stmt, [features], 1)

prediction = results[0]['predict']
TD['new']['class'] = prediction

return 'MODIFY'

$$ LANGUAGE plpython3u;


-- Drop trigger if it exists
DROP TRIGGER IF EXISTS classify_iris
  ON iris;

CREATE TRIGGER classify_iris
BEFORE INSERT OR UPDATE ON "iris"
FOR EACH ROW 
EXECUTE PROCEDURE classification_trigger(
	'/home/vagrant/vagrant_data/dataset/saved_models/decision_tree.joblib', 
	'class',
	'sepal_length', 
	'sepal_width', 
	'petal_length', 
	'petal_width' 
);


-- TEST WITH SOME DATA (Available in /home/vagrant/vagrant_data/dataset/sample_data/iris_30.data)
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.5,1.5,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.0,2.2,5.0,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.7,3.1,4.7,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.2,2.9,4.3,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.6,3.2,1.4,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.7,2.9,4.2,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.4,3.0,4.5,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.7,3.3,5.7,2.1);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.5,2.5,4.0,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.5,3.0,5.2,2.0);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.9,3.0,1.4,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.2,3.4,1.4,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.8,3.0,5.5,2.1);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.0,3.4,1.5,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.4,3.4,1.5,0.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.8,3.0,1.4,0.1);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.4,2.9,4.3,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.1,2.6,5.6,1.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.8,2.8,5.1,2.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (7.7,2.8,6.7,2.0);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.8,2.7,5.1,1.9);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.0,3.6,1.4,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.5,2.3,4.0,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.1,3.8,1.6,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.5,2.8,4.6,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.1,3.8,1.9,0.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.4,3.2,4.5,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.1,3.8,1.5,0.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.0,3.3,1.4,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.8,3.0,1.4,0.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.4,3.9,1.7,0.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.1,2.8,4.0,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.2,3.4,5.4,2.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.5,2.4,3.8,1.1);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.3,2.8,5.1,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.1,2.9,4.7,1.4);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.7,2.8,4.5,1.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.9,2.5,4.5,1.7);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.3,2.5,4.9,1.5);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.7,3.8,1.7,0.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.7,2.5,5.0,2.0);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.7,3.0,5.0,1.7);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (5.0,2.0,3.5,1.0);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (4.7,3.2,1.3,0.2);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (6.8,3.2,5.9,2.3);
INSERT INTO iris (sepal_length, sepal_width, petal_length, petal_width) VALUES (7.7,2.6,6.9,2.3);




