\echo Use "CREATE EXTENSION pgpyml" to load this file. \quit

/**
* Predict the classification of the given features values
*/
CREATE OR REPLACE FUNCTION predict(model_path text, input_values real[]) RETURNS TEXT[] AS
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
CREATE OR REPLACE FUNCTION predict_int(model_path text, input_values real[]) RETURNS INT[] AS
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
CREATE OR REPLACE FUNCTION predict_real(model_path text, input_values real[]) RETURNS REAL[] AS
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
CREATE OR REPLACE FUNCTION predict_table_row(model_path text, table_name text, columns_name text[], id int) RETURNS TEXT AS
$$
features = ','.join([plpy.quote_ident(c_name) + '::real' for c_name in columns_name])
selected_values = plpy.execute('SELECT * FROM predict(%s, (SELECT ARRAY[[%s]] FROM %s WHERE id = %d))' % (plpy.quote_literal(model_path), features, plpy.quote_ident(table_name), id), 1)

return selected_values[0]['predict'][0]
$$ LANGUAGE plpython3u;
