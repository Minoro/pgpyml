"""This script will train and save a new model to be used inside your Postgres database.
This script will use only 70% of the dataset, the others 30% you can use to simulate new data.
"""

import pandas as pd
from sklearn import datasets
from sklearn import metrics
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB
from joblib import dump, load

RANDOM_STATE = 42

csv_columns = [
    'wine_class',
    'alcohol',
	'malic_acid',
	'ash',
	'alcalinity',
	'magnesium',
	'phenols',
	'flavanoids',
	'nonflavanoid',
	'proanthocyanins',
	'color',
	'huue',
	'od280',
	'proline'
]

df = pd.read_csv('../wine_70.data', names=csv_columns)

train, test = train_test_split(df, test_size = 0.3, stratify = df['wine_class'], random_state = RANDOM_STATE)
X_train = train[csv_columns[1:]]
y_train = train.wine_class
X_test = test[csv_columns[1:]]
y_test = test.wine_class

model = GaussianNB()
model.fit(X_train, y_train)

prediction = model.predict(X_test)
print('The accuracy of the model is {:.3f}'.format(metrics.accuracy_score(prediction, y_test)))

print('Saving model...')
dump(model, './wine_naive_bayes.joblib')
    
print('Model saved!')
print('Done!')
