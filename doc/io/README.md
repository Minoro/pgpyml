# Loading the Model

The `pgpyml` extension will load the model you trained in the memory to be used in a Postgres session. The model will be loaded to the `GD` dictionary, the key will be the path to your model prefixed with `model_`. That means that if you load the model `/home/vagrant/examples/iris/models/iris_decision_tree.joblib` you will be able to access it in your `plpython3u` function with:

```python
model = GD['model_/home/vagrant/examples/iris/models/iris_decision_tree.joblib']
```

If you are using the `predict` function or the classification triggers you don't need to worry about loading the model by yourself, the `pgpyml` extension will load it and store in the `GD` dictionary.

Although you don't need to load the model manually, you can use the `load_model` function to load (or pre-load) a specific model to the memory. You just need to call this function with passing the model path as argument:

```sql
SELECT load_model('/home/vagrant/examples/iris/models/iris_decision_tree.joblib');
```

The `load_model` signature is:
```sql
FUNCTION load_model(model_path text) RETURNS BYTEA
```

When you invoke the function `load_model` manually it will replace any model that already is in the memory to the specified path and will returs a `bytea` representation of the loaded model.

The model must be a `joblib` file. You can refer the [sklearn model persistence documentation](https://scikit-learn.org/stable/modules/model_persistence.html) to see more about saving your model. Pay extra attention to the [Security & maintainability limitations](https://scikit-learn.org/stable/modules/model_persistence.html#security-maintainability-limitations) section, the information in that section can be applyed to `pgpyml`. **Never use an untrusted pickle/joblib file**.

# Checking loaded models

Once you have used one of the predition functions, classification trigger or even loaded your model mannually you may want to know wich models are in your memory. You can use the `get_loaded_models` function to check the models that are stored in your memory. This function will return a table that cotains the model key in the `GD` dictionary, the model path used to load the model and a `bytea` representation of the loaded model.

You can call this function using:

```sql
SELECT * FROM get_loaded_models();
```

The `get_loaded_models` signature is:

```sql
FUNCTION get_loaded_models() RETURNS 
TABLE  (
    model_key TEXT,
    model_path TEXT,
    model BYTEA
) 
```

If you want to check if a specific model is loaded in your memory you can use the `is_model_loaded` function to check for a specific model:

```sql
SELECT is_model_loaded('/home/vagrant/examples/iris/models/iris_decision_tree.joblib');
-- Returns True if the model is already loaded in the memory
```

The function signature is:
```sql
FUNCTION is_model_loaded(model_path text) RETURNS BOOL
```

# Remove models from the memory

If you want to remove a model from the memory you can use the `unload_model` function. You just need to pass the model path and if it is found in the `GD` dictionay it will be deleted:

```sql
-- Remove the model from the memory
SELECT unload_model('/home/vagrant/examples/iris/models/iris_decision_tree.joblib');

-- Checks if the model stills in the GD dictionary
SELECT is_model_loaded('/home/vagrant/examples/iris/models/iris_decision_tree.joblib');
-- Returns False
```

The function signature is:

```sql
FUNCTION unload_model(model_path text) RETURNS VOID
```
