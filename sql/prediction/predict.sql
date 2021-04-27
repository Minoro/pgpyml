\echo Use "CREATE EXTENSION pgpyml" to load this file. \quit

/**
* Predict the classification of the given features values
*/
CREATE OR REPLACE FUNCTION predict(model_path text, input_values real[]) RETURNS TEXT[] AS
$$
model_key = 'model_' + model_path
if model_key in SD:
    clf = SD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    SD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;


/**
* Predict the classification of the given features as int values
*/
CREATE OR REPLACE FUNCTION predict_int(model_path text, input_values real[]) RETURNS INT[] AS
$$
model_key = 'model_' + model_path
if model_key in SD:
    clf = SD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    SD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;


/**
* Predict the classification of the given features as real values
*/
CREATE OR REPLACE FUNCTION predict_real(model_path text, input_values real[]) RETURNS REAL[] AS
$$
model_key = 'model_' + model_path
if model_key in SD:
    clf = SD[model_key]
else:
    from joblib import load
    clf = load(model_path) 
    SD[model_key] = clf

prediction = clf.predict(input_values)
return prediction
$$ LANGUAGE plpython3u;
