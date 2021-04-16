\echo Use "CREATE EXTENSION pgpyml" to load this file. \quit
 
CREATE EXTENSION IF NOT EXISTS plpython3u;


/**
* Predict the classification of the given features values
*/
CREATE OR REPLACE FUNCTION predict(model_path text, input_values real[]) RETURNS TEXT AS
$$
model_key = 'model_' + model_path
if model_key in SD:
    clf = SD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    SD[model_key] = clf
	
features = input_values 
if type(input_values) == list and len(input_values) > 1:
    features = [input_values]

prediction = clf.predict(features)

return prediction[0]

$$ LANGUAGE plpython3u;


/**
* Create a funtction to be used in triggers to classify data and save in a column
* The first parameter must be the model path
* The second parameter must be to column where the classification result will be saved
* The others arguments will be used as features columns names
*/
CREATE OR REPLACE FUNCTION classification_trigger() RETURNS trigger AS
$$
model_path = TD['args'][0] 
target_column_name = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

# Call the prediction function
stmt = plpy.prepare("SELECT predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, features], 1)

prediction = results[0]['predict']
TD['new'][target_column_name] = prediction

return 'MODIFY'

$$ LANGUAGE plpython3u;
