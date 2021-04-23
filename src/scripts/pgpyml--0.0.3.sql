
/**
* Predict the data and raise an exception if the prediction is equals the value informed.
* The prediction will not be stored
* The first argument is the model path
* The second argurment is the value to be compared. If the prediction is equals to this value it will raise an exception
* Any other argument will be used as features by the model.
*/
CREATE OR REPLACE FUNCTION trigger_abort_if_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
compare_value = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction == compare_value:
	plpy.error('The value {} is not allowed'.format(prediction))

return 'MODIFY'

$$ LANGUAGE plpython3u;


/**
* Predict the data and raise an exception if the prediction is equals the value informed.
* The prediction will be stored;
* The first argument is the model path;
* The second argument is the name of the column where the prediction will be stored;
* The third argurment is the value to be compared. If the prediction is equals to this value it will raise an exception;
* Any other argument will be used as features by the model.;
*/
CREATE OR REPLACE FUNCTION trigger_classification_or_abort_if_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
compare_value = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction == compare_value:
	plpy.error('The value {} is not allowed'.format(prediction))

return 'MODIFY'

$$ LANGUAGE plpython3u;
