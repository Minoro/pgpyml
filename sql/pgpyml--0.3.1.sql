/**
* Create a new schema to be used by the extension.
* By default the extension is not installed in this schema
*/

CREATE SCHEMA IF NOT EXISTS pgpyml;
/**
* Read the model from the disk to the memory and return it as an byte array.
* The model will be stored on the special GD dictionary.
* The model path will be prefixed with 'model_' and will be used as key to access to model in the GD dictionary.
*/
CREATE OR REPLACE FUNCTION pgpyml.load_model(model_path text) RETURNS BYTEA AS
$$

import pickle
import io
from joblib import load
model_key = 'model_' + model_path

if not model_path.endswith('.joblib'):
    plpy.error('The model_path must be a joblib file')
    return None

clf = load(model_path) 
GD[model_key] = clf

model_buffer = io.BytesIO()
pickle.dump(clf, model_buffer)

return model_buffer.getbuffer()
$$ LANGUAGE plpython3u;

/**
* Get the models loaded in the memory
*/
CREATE OR REPLACE FUNCTION pgpyml.get_loaded_models() RETURNS 
TABLE  (
    model_key TEXT,
    model_path TEXT,
    model BYTEA
) AS
$$
import pickle
import io

models = []
for k in GD:
    if k.startswith('model_'):
	
        model_buffer = io.BytesIO()
        pickle.dump(GD[k], model_buffer)
		
        models.append({
            'model_key': k,
            'model_path': k[6:],
            'model': model_buffer
        })

return models
$$ LANGUAGE plpython3u;	


/**
* Check if the model is already loaded to the memory.
*/
CREATE OR REPLACE FUNCTION pgpyml.is_model_loaded(model_path text) RETURNS BOOL AS
$$

model_key = 'model_' + model_path

if model_key in GD:
    return True
	
return False
$$ LANGUAGE plpython3u;


/**
* Remove the model from the memory if it is loaded.
* The first argument is the model path that was loaded to the memory
*/
CREATE OR REPLACE FUNCTION pgpyml.unload_model(model_path text) RETURNS VOID AS
$$

model_key = 'model_' + model_path
if not model_path.endswith('.joblib'):
    plpy.error('The model_path must be a joblib file')
    return None

if model_key in GD:
    del GD[model_key]

$$ LANGUAGE plpython3u;

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
/**
* Create a funtction to be used in triggers to classify data and save in a column
* The first parameter must be the model path
* The second parameter must be to column where the classification result will be saved
* The others arguments will be used as features columns names
*/
CREATE OR REPLACE FUNCTION pgpyml.classification_trigger() RETURNS trigger AS
$$
model_path = TD['args'][0] 
target_column_name = TD['args'][1]
features_columns_names = TD['args'][2:]

features = []
for feature_column_name in features_columns_names:
	features.append(TD['new'][feature_column_name])
    
stmt = plpy.prepare("SELECT pgpyml.predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]
TD['new'][target_column_name] = prediction

return 'MODIFY'

$$ LANGUAGE plpython3u;

/**
* Predict the classification of the given features values
*/
CREATE OR REPLACE FUNCTION pgpyml.predict(model_path text, input_values real[]) RETURNS TEXT[] AS
$$
model_key = 'model_' + model_path
if model_key in GD:
    clf = GD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    GD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;


/**
* Predict the classification of the given features as int values
*/
CREATE OR REPLACE FUNCTION pgpyml.predict_int(model_path text, input_values real[]) RETURNS INT[] AS
$$
model_key = 'model_' + model_path
if model_key in GD:
    clf = GD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    GD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;


/**
* Predict the classification of the given features as real values
*/
CREATE OR REPLACE FUNCTION pgpyml.predict_real(model_path text, input_values real[]) RETURNS REAL[] AS
$$
model_key = 'model_' + model_path
if model_key in GD:
    clf = GD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    GD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;

/**
* Use the model to predict data already stored on the table
*/
CREATE OR REPLACE FUNCTION pgpyml.predict_table_row(model_path text, table_name text, columns_name text[], id int) RETURNS TEXT AS
$$
features = ','.join([plpy.quote_ident(c_name) + '::real' for c_name in columns_name])
selected_values = plpy.execute('SELECT * FROM pgpyml.predict(%s, (SELECT ARRAY[[%s]] FROM %s WHERE id = %d))' % (plpy.quote_literal(model_path), features, plpy.quote_ident(table_name), id), 1)

return selected_values[0]['predict'][0]
$$ LANGUAGE plpython3u;
