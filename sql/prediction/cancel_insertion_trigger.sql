
/**
* Predict the data and raise an exception if the prediction is equals the value informed.
* The prediction will not be stored
* The first argument is the model path
* The second argurment is the value to be compared. If the prediction is equals to this value it will raise an exception
* Any other argument will be used as the columns name with the features to be predicted.
*/
CREATE OR REPLACE FUNCTION trigger_abort_if_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
compare_value = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT pgpyml.predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction == compare_value:
	plpy.error('The value {} is not allowed'.format(prediction))

return 'MODIFY'

$$ LANGUAGE plpython3u;


/**
* Predict the data and raise an exception if the prediction is equals the value informed.
* The prediction will be stored
* The first argument is the model path
* The second argument is the name of the column where the prediction will be stored
* The third argurment is the value to be compared. If the prediction is equals to this value it will raise an exception
* Any other argument will be used as the columns name with the features to be predicted.
*/
CREATE OR REPLACE FUNCTION trigger_classification_or_abort_if_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
target_column_name = TD['args'][1]
compare_value = TD['args'][2]
features_columns_names = TD['args'][3:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT pgpyml.predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction == compare_value:
	plpy.error('The value {} is not allowed'.format(prediction))

TD['new'][target_column_name] = prediction

return 'MODIFY'

$$ LANGUAGE plpython3u;


/**
* This funtion use the informed model to predict a value and abort the transaction unless the predicted values is equals
* the value passed as argument. The prediction will not be stored.
* The first argument is the model path
* The second argument is the expected value. The transaction will be aborted if the value is different of this value.
* Any other argument will be used as the columns name with the features to be predicted.
*/
CREATE OR REPLACE FUNCTION trigger_abort_unless_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
expected_value = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT pgpyml.predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction != expected_value:
	plpy.error('The value {} is not allowed'.format(prediction))
	return None

return 'MODIFY'

$$ LANGUAGE plpython3u;


/**
* This funtion use the informed model to predict a value and abort the transaction unless the predicted values is equals
* the value passed as argument. The prediction will be stored.
* The first argument is the model path
* The second argument is the name of the column where the prediction will be stored
* The third argurment is the value to be compared. If the prediction is equals to this value it will raise an exception
* Any other argument will be used as the columns name with the features to be predicted.
*/
CREATE OR REPLACE FUNCTION pgpyml.trigger_classification_or_abort_unless_prediction_is() RETURNS trigger AS
$$
model_path = TD['args'][0] 
target_column_name = TD['args'][1]
compare_value = TD['args'][2]
features_columns_names = TD['args'][3:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])

stmt = plpy.prepare("SELECT pgpyml.predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]

if prediction != compare_value:
	plpy.error('The value {} is not allowed'.format(prediction))
	return None

TD['new'][target_column_name] = prediction

return 'MODIFY'

$$ LANGUAGE plpython3u;