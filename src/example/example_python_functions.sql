-- CREATE EXTENSION plpython3u;

-- Basic function with python
CREATE OR REPLACE FUNCTION say_hello_world() RETURNS TEXT AS
$$
  return 'Hello, World'
$$ LANGUAGE plpython3u;

-- Basic function with argument
CREATE OR REPLACE FUNCTION greet_person(name text) RETURNS TEXT AS
$$
  greeting = 'Hello, ' + name
  return greeting
$$ LANGUAGE plpython3u;

-- SELECT * FROM say_hello_world()

-- SELECT * FROM greet_person('Maya');