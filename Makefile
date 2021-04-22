EXTENSION = pgpyml
DATA = src/scripts/pgpyml--0.0.2.sql
 
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)