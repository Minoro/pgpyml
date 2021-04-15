CREATE EXTENSION plpython3u;


CREATE OR REPLACE FUNCTION predict(model_path text, input_values real[]) RETURNS TEXT AS
$$
from joblib import load

clf = load(model_path) 

prediction = clf.predict(input_values)

return prediction[0]

$$ LANGUAGE plpython3u;


-- SELECT * FROM predict('/home/vagrant/vagrant_data/saved_models/decision_tree.joblib', '{{1.0, 1.5, 1.5, 0.1}}');
