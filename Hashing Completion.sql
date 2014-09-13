select
  unhashed, hashed,
  unhashed/(unhashed+hashed)*100 as uncompleted,
    hashed/(unhashed+hashed)*100 as completed
from 
 (SELECT count(id) as unhashed FROM filecollector.filecollector where hash is NULL) as unhashed,
 (SELECT count(id) as hashed FROM filecollector.filecollector where hash is not NULL) as hashed;