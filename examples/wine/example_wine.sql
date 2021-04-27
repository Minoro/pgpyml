/**
* Example using the Wine dataset from UCI
* https://archive.ics.uci.edu/ml/datasets/Wine
* 
* The data was splited in two sets. One with 70% of the data and another with 30%.
* The first set is in the file examples/wine/dataset/wine_70.data, this set will be
* used to train our model to classify new data
* The second set is in the file examples/wine/dataset/wine_30.data, this simulate new
* data that we will store in our table.
*
* We will create a table and store the data used to train the model in the
* examples/wine/model/train_wine_naive_bayes.py script.
* After that, we will save our model in the directory in examples/wine/model/wine_naive_bayes.joblib
*
* With our trained model, we will create a trigger to classify new data and 
* store the classification result in the 'wine_class' column.
*/

-- Create the table where we will store our data
CREATE TABLE wine (
	id SERIAL PRIMARY KEY,
	wine_class INT, -- where we will insert the classification result
	alcohol FLOAT,
	malic_acid FLOAT,
	ash FLOAT,
	alcalinity FLOAT,
	magnesium FLOAT,
	phenols FLOAT,
	flavanoids FLOAT,
	nonflavanoid FLOAT,
	proanthocyanins FLOAT,
	color FLOAT,
	huue FLOAT,
	od280 FLOAT,
	proline float
);

-- Populate the table with the data used to train our model
COPY wine(
	wine_class,
    alcohol,
	malic_acid,
	ash,
	alcalinity,
	magnesium,
	phenols,
	flavanoids,
	nonflavanoid,
	proanthocyanins,
	color,
	huue,
	od280,
	proline
)
FROM '/home/vagrant/vagrant_data/wine/dataset/wine_70.data'
DELIMITER ',';

-- You can run the example/wine/models/train_wine_naive_bayes.py to train and save your model
-- The model will use the values in the column 'wine_class' as target

-- If you want to see the results of your model over your stored data you can use the predict_table_row function
SELECT * FROM predict_table_row(
	'/home/vagrant/vagrant_data/wine/models/wine_naive_bayes.joblib',                      -- The trained model
	'wine',                                                                                 -- Table with the data
	'{"alcohol", "malic_acid", "ash", "alcalinity", "magnesium", "phenols",                 
	"flavanoids", "nonflavanoid", "proanthocyanins", "color", "hue", "od280", "proline"}',  -- The columns used as feature
	1                                                                                       -- The ID of your data
);


-- After trained you can create a trigger to populate the new data that you insert into the table
-- You can use the function classification_trigger to create a trigger to apply your model over your data
-- and save it in a specifc column. This columns must exists in the same table that the trigger are acting.

CREATE TRIGGER classify_wine
BEFORE INSERT OR UPDATE ON "wine"
FOR EACH ROW 
EXECUTE PROCEDURE classification_trigger(
	'/home/vagrant/vagrant_data/wine/models/wine_naive_bayes.joblib', -- Model
	'wine_class', -- Column where you will store the result of the classification
    'alcohol', -- Features
	'malic_acid',
	'ash',
	'alcalinity',
	'magnesium',
	'phenols',
	'flavanoids',
	'nonflavanoid',
	'proanthocyanins',
	'color',
	'hue',
	'od280',
	'proline'
);

-- With the trigger created you can insert a new row in your table
-- Notice that the following insert doesn't insert any value to 'wine_class' column
INSERT INTO wine (
	alcohol,
	malic_acid,
	ash,
	alcalinity,
	magnesium,
	phenols,
	flavanoids,
	nonflavanoid,
	proanthocyanins,
	color,
	hue,
	od280,
	proline)
VALUES (14.83,1.64,2.17,14,97,2.8,2.98,.29,1.98,5.2,1.08,2.85,1045);

-- Then you can check the newly inserted data
-- If everything works, the column 'wine_class' will be populated
SELECT * FROM wine WHERE id = (SELECT MAX(id) FROM wine);

/**
-- If you want to insert the data available in the file examples/wine/dataset/wine_30.data in your database to test the new trigger you can use the following commands.
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.83,1.64,2.17,14,97,2.8,2.98,.29,1.98,5.2,1.08,2.85,1045);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.33,1.1,2.28,16,101,2.05,1.09,.63,.41,3.27,1.25,1.67,680);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.86,1.35,2.27,16,98,2.98,3.15,.22,1.85,7.22,1.01,3.55,1045);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.85,3.27,2.58,22,106,1.65,.6,.6,.96,5.58,.87,2.11,570);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.07,1.5,2.1,15.5,98,2.4,2.64,.28,1.37,3.7,1.18,2.69,1020);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.42,1.61,2.19,22.5,108,2,2.09,.34,1.61,2.06,1.06,2.96,345);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.19,1.59,2.48,16.5,108,3.3,3.93,.32,1.86,8.7,1.23,2.82,1680);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.64,1.36,2.02,16.8,100,2.02,1.41,.53,.62,5.75,.98,1.59,450);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.1,2.02,2.4,18.8,103,2.75,2.92,.32,2.38,6.2,1.07,2.75,1060);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.74,1.67,2.25,16.4,118,2.6,2.9,.21,1.62,5.85,.92,3.2,1060);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.86,1.35,2.32,18,122,1.51,1.25,.21,.94,4.1,.76,1.29,630);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.2,3.03,2.32,19,96,1.25,.49,.4,.73,5.5,.66,1.83,510);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.7,3.55,2.36,21.5,106,1.7,1.2,.17,.84,5,.78,1.29,600);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.38,1.87,2.38,12,102,3.3,3.64,.29,2.96,7.5,1.2,3,1547);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.51,1.73,1.98,20.5,85,2.2,1.92,.32,1.48,2.94,1.04,3.57,672);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.27,4.28,2.26,20,120,1.59,.69,.43,1.35,10.2,.59,1.56,835);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.56,1.71,2.31,16.2,117,3.15,3.29,.34,2.34,6.13,.95,3.38,795);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.34,2.45,2.46,21,98,2.56,2.11,.34,1.31,2.8,.8,3.38,438);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.37,1.17,1.92,19.6,78,2.11,2,.27,1.04,4.68,1.12,3.48,510);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (11.64,2.06,2.46,21.6,84,1.95,1.69,.48,1.35,2.8,1,2.75,680);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.72,1.81,2.2,18.8,86,2.2,2.53,.26,1.77,3.9,1.16,3.14,714);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.37,1.13,2.16,19,87,3.5,3.1,.19,1.87,4.45,1.22,2.87,420);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (11.82,1.72,1.88,19.5,86,2.5,1.64,.37,1.42,2.06,.94,2.44,415);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.08,3.9,2.36,21.5,113,1.41,1.39,.34,1.14,9.40,.57,1.33,550);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.68,1.83,2.36,17.2,104,2.42,2.69,.42,1.97,3.84,1.23,2.87,990);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.21,1.19,1.75,16.8,151,1.85,1.28,.14,2.5,2.85,1.28,3.07,718);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.51,1.24,2.25,17.5,85,2,.58,.6,1.25,5.45,.75,1.51,650);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.29,3.17,2.21,18,88,2.85,2.99,.45,2.81,2.3,1.42,2.83,406);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.58,1.29,2.1,20,103,1.48,.58,.53,1.4,7.6,.58,1.55,640);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.83,1.65,2.6,17.2,94,2.45,2.99,.22,2.29,5.6,1.24,3.37,1265);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.77,1.9,2.68,17.1,115,3,2.79,.39,1.68,6.3,1.13,2.93,1375);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.88,5.04,2.23,20,80,.98,.34,.4,.68,4.9,.58,1.33,415);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.23,3.3,2.28,18.5,98,1.8,.83,.61,1.87,10.52,.56,1.51,675);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.3,1.92,2.72,20,120,2.8,3.14,.33,1.97,6.2,1.07,2.65,1280);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.81,2.31,2.4,24,98,1.15,1.09,.27,.83,5.7,.66,1.36,560);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.08,1.39,2.5,22.5,84,2.56,2.29,.43,1.04,2.9,.93,3.19,385);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.22,3.99,2.51,13.2,128,3,3.04,.2,2.08,5.1,.89,3.53,760);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (11.03,1.51,2.2,21.5,85,2.46,2.17,.52,2.01,1.9,1.71,2.87,407);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.29,2.83,2.22,18,88,2.45,2.25,.25,1.99,2.15,1.15,3.3,290);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.2,1.76,2.45,15.2,112,3.27,3.39,.34,1.97,6.75,1.05,2.85,1450);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.05,3.86,2.32,22.5,85,1.65,1.59,.61,1.62,4.8,.84,2.01,515);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.38,3.59,2.28,16,102,3.25,3.17,.27,2.19,4.9,1.04,3.44,1065);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.75,1.73,2.39,11.4,91,3.1,3.69,.43,2.81,5.4,1.25,2.73,1150);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.71,1.86,2.36,16.6,101,2.61,2.88,.27,1.69,3.8,1.11,4,1035);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.69,3.26,2.54,20,107,1.83,.56,.5,.8,5.88,.96,1.82,680);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.11,1.01,1.7,15,78,2.98,3.18,.26,2.28,5.3,1.12,3.18,502);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (14.16,2.51,2.48,20,91,1.68,.7,.44,1.24,9.7,.62,1.71,660);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.58,1.66,2.36,19.1,106,2.86,3.19,.22,1.95,6.9,1.09,2.88,1515);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (12.37,1.63,2.3,24.5,88,2.22,2.45,.4,1.9,2.12,.89,2.78,342);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.05,1.77,2.1,17,107,3,3,.28,2.03,5.04,.88,3.35,885);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.76,1.53,2.7,19.5,132,2.95,2.74,.5,1.35,5.4,1.25,3,1235);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (11.84,2.89,2.23,18,112,1.72,1.32,.43,.95,2.65,.96,2.52,500);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.41,3.84,2.12,18.8,90,2.45,2.68,.27,1.48,4.28,.91,3,1035);
INSERT INTO wine (alcohol, malic_acid, ash, alcalinity, magnesium, phenols, flavanoids, nonflavanoid, proanthocyanins, color, hue, od280, proline) VALUES (13.75,1.73,2.41,16,89,2.6,2.76,.29,1.81,5.6,1.15,2.9,1320);
*/

