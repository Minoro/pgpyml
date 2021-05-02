
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
    
stmt = plpy.prepare("SELECT predict($1, $2)", ['text', 'real[]'])
results =  plpy.execute(stmt, [model_path, [features]], 1)

prediction = results[0]['predict'][0]
TD['new'][target_column_name] = prediction

return 'MODIFY'

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