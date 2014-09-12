SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

DROP SCHEMA IF EXISTS `filecollector` ;
CREATE SCHEMA IF NOT EXISTS `filecollector` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `filecollector` ;

-- -----------------------------------------------------
-- Table `filecollector`.`filecollector`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `filecollector`.`filecollector` ;

CREATE  TABLE IF NOT EXISTS `filecollector`.`filecollector` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `basedir` VARCHAR(4096) NOT NULL ,
  `path` VARCHAR(4096) NOT NULL ,
  `filename` VARCHAR(255) NOT NULL ,
  `filenamehash` varchar(128) NULL,
  `hash` VARCHAR(128) NULL ,
  PRIMARY KEY (`id`),
  constraint filenamehashes unique ( filenamehash )
 )
ENGINE = InnoDB;


CREATE USER `filecollector` IDENTIFIED BY '6067d82ee7f4303d69db7e32b7e13684';

grant INSERT on TABLE `filecollector`.`filecollector` to filecollector;
grant UPDATE on TABLE `filecollector`.`filecollector` to filecollector;
grant DELETE on TABLE `filecollector`.`filecollector` to filecollector;
grant SELECT on TABLE `filecollector`.`filecollector` to filecollector;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
