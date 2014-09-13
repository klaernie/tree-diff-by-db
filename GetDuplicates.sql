select `id`,`basedir`,`path`,`filename`,f.`hash`
from filecollector.filecollector as f,
       (select hash, count(id) as hashcount from filecollector.filecollector group by hash HAVING hashcount >1 ) as hashes
where f.hash = hashes.hash
order by f.hash;
