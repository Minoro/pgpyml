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
