import pandas as pd
from sklearn.model_selection import train_test_split
import numpy as np
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics
# from joblib import dump, load
from pickle import dump

df = pd.read_csv('../../dataset/sample_data/iris_70.data', names=['sepal_length', 'sepal_width', 'petal_length', 'petal_width', 'class_name'])

train, test = train_test_split(df, test_size = 0.3, stratify = df['class_name'], random_state = 42)
X_train = train[['sepal_length','sepal_width','petal_length','petal_width']]
y_train = train.class_name
X_test = test[['sepal_length','sepal_width','petal_length','petal_width']]
y_test = test.class_name

model = DecisionTreeClassifier()

model.fit(X_train, y_train)

prediction = model.predict(X_test)
print('The accuracy of the model is {:.3f}'.format(metrics.accuracy_score(prediction, y_test)))

print('Saving model...')
with open('../../dataset/saved_models/decision_tree.pkl', 'w') as f:
    dump(model, f)
    
print('Model saved!')

print(prediction[0])

print('Done!')