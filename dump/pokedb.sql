DROP DATABASE IF EXISTS pokedb;

CREATE DATABASE IF NOT EXISTS pokedb DEFAULT CHARSET = utf8mb4;
use pokedb;

CREATE TABLE IF NOT EXISTS Region
(
    Nom VARCHAR(50) NOT NULL,
    PRIMARY KEY (Nom)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Route
(
    Numero INT UNSIGNED NOT NULL,
    PRIMARY KEY (Numero)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Sexe
(
    Intitule VARCHAR(25) NOT NULL,
    PRIMARY KEY (Intitule)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Categorie
(
    Intitule VARCHAR(50),
    PRIMARY KEY (Intitule)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Type
(
    Intitule VARCHAR(100) NOT NULL,
    PRIMARY KEY (Intitule)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Pokemon
(
    Id                INT UNSIGNED   NOT NULL,
    Nom               VARCHAR(50)    NOT NULL UNIQUE,
    Description       VARCHAR(255)   NOT NULL,
    Taille            FLOAT UNSIGNED NOT NULL,
    Poids             FLOAT UNSIGNED NOT NULL,
    ExperienceMinimum INT UNSIGNED   NOT NULL,
    ExperienceMaximum INT UNSIGNED   NOT NULL,
    Evolution         INT UNSIGNED   NULL,
    Niveau            INT UNSIGNED   NULL,
    Mega              BOOLEAN        NULL,
    PRIMARY KEY (Id),
    FOREIGN KEY (Evolution) REFERENCES Pokemon (Id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Localisation
(
    Region    VARCHAR(50)  NOT NULL,
    Route     INT UNSIGNED NOT NULL,
    IdPokemon INT UNSIGNED NOT NULL,
    FOREIGN KEY (Region) REFERENCES Region (Nom),
    FOREIGN KEY (Route) REFERENCES Route (Numero),
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (Id),
    PRIMARY KEY (Route, IdPokemon)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Categorisation
(
    IdPokemon INT UNSIGNED NOT NULL,
    Categorie VARCHAR(50)  NOT NULL,
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (Id),
    FOREIGN KEY (Categorie) REFERENCES Categorie (Intitule),
    PRIMARY KEY (IdPokemon, Categorie)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Ville
(
    Nom    VARCHAR(50) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    PRIMARY KEY (Nom),
    FOREIGN KEY (Region) REFERENCES Region (Nom)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Genre
(
    IdPokemon   INT UNSIGNED   NOT NULL,
    Sexe        VARCHAR(50)    NOT NULL,
    Pourcentage FLOAT UNSIGNED NOT NULL,
    PRIMARY KEY (IdPokemon, Sexe),
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (Id),
    FOREIGN KEY (Sexe) REFERENCES Sexe (Intitule)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `Force`
(
    IdPokemon INT UNSIGNED NOT NULL,
    Type      VARCHAR(100) NOT NULL,
    FOREIGN KEY (Type) REFERENCES Type (Intitule),
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (id),
    PRIMARY KEY (IdPokemon, Type)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Faiblesse
(
    IdPokemon INT UNSIGNED NOT NULL,
    Type      VARCHAR(100) NOT NULL,
    FOREIGN KEY (Type) REFERENCES Type (Intitule),
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (id),
    PRIMARY KEY (IdPokemon, Type)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Typage
(
    IdPokemon INT UNSIGNED NOT NULL,
    Type      VARCHAR(100) NOT NULL,
    FOREIGN KEY (Type) REFERENCES Type (Intitule),
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (Id),
    PRIMARY KEY (IdPokemon, Type)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Technique
(
    Intitule       VARCHAR(100)  NOT NULL,
    Description    VARCHAR(2048) NOT NULL,
    Puissance      INT UNSIGNED  NOT NULL,
    `Precision`    INT UNSIGNED  NOT NULL,
    Pp             INT UNSIGNED  NOT NULL,
    Specialisation VARCHAR(100)  NOT NULL,
    FOREIGN KEY (Specialisation) REFERENCES Type (Intitule),
    PRIMARY KEY (Intitule)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS Attaque
(
    IdPokemon INT UNSIGNED NOT NULL,
    Technique VARCHAR(50)  NOT NULL,
    FOREIGN KEY (IdPokemon) REFERENCES Pokemon (Id),
    FOREIGN KEY (Technique) REFERENCES Technique (Intitule),
    PRIMARY KEY (IdPokemon, Technique)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

/* Procedures */

START TRANSACTION;

DELIMITER //

CREATE PROCEDURE pokemon_definir_categorisation(IN pokemon VARCHAR(50), IN categorisation VARCHAR(50))
BEGIN
    INSERT INTO Categorisation VALUES ((SELECT id FROM Pokemon WHERE Nom = pokemon), categorisation);
END //

CREATE PROCEDURE pokemon_definir_type(IN pokemon VARCHAR(50), IN type VARCHAR(100))
BEGIN
    INSERT INTO Typage VALUES ((SELECT id FROM Pokemon WHERE Nom = pokemon), type);
END //

CREATE PROCEDURE pokemon_definir_attaque(IN pokemon VARCHAR(50), IN attaque VARCHAR(50))
BEGIN
    INSERT INTO Attaque VALUES ((SELECT id FROM Pokemon WHERE Nom = pokemon), attaque);
END //

CREATE PROCEDURE pokemon_definir_force(IN pokemon VARCHAR(50), IN `force` VARCHAR(100))
BEGIN
    INSERT INTO `Force` VALUES ((SELECT id FROM Pokemon WHERE Nom = pokemon), `force`);
END //

CREATE PROCEDURE pokemon_definir_faiblesse(IN pokemon VARCHAR(50), IN faiblesse VARCHAR(100))
BEGIN
    INSERT INTO pokedb.Faiblesse VALUES ((SELECT id FROM Pokemon WHERE Nom = pokemon), faiblesse);
END //

CREATE PROCEDURE pokemon_definir_genre(IN pokemon VARCHAR(50), IN pourcentage_femelle FLOAT, pourcentage_male FLOAT)
BEGIN
    INSERT INTO Genre VALUES ((SELECT Id FROM Pokemon WHERE Nom = pokemon), "Femelle", pourcentage_femelle);
    INSERT INTO Genre VALUES ((SELECT Id FROM Pokemon WHERE Nom = pokemon), "M??le", pourcentage_male);
END //

CREATE PROCEDURE pokemon_definir_localisation(IN region VARCHAR(50), IN route INT UNSIGNED, pokemon VARCHAR(50))
BEGIN
    INSERT INTO Localisation VALUES (region, route, (SELECT Id FROM Pokemon WHERE Nom = pokemon));
END //

CREATE PROCEDURE pokemon_actualiser_evolution(IN pokemon_de_base VARCHAR(50), IN pokemon_evolue VARCHAR(50),
                                              IN niveau INT UNSIGNED, IN mega BOOLEAN)
BEGIN
    UPDATE Pokemon
    SET Evolution = (SELECT Id FROM (SELECT * FROM Pokemon) AS p WHERE Nom = pokemon_evolue),
        Niveau    = niveau,
        Mega      = mega
    WHERE Id = (SELECT Id FROM (SELECT * FROM Pokemon) AS p WHERE Nom = pokemon_de_base);
END //

DELIMITER ;

COMMIT;

/* Triggers */
DELIMITER //
CREATE TRIGGER pokemon_verifier_faiblesse
    BEFORE INSERT
    ON Faiblesse
    FOR EACH ROW
BEGIN
    DECLARE est_une_force INTEGER UNSIGNED;
    DECLARE est_de_type INTEGER UNSIGNED;

    SELECT COUNT(*) INTO est_une_force FROM `Force` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    SELECT COUNT(*) INTO est_de_type FROM `Typage` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    IF est_une_force > 0 OR est_de_type > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La faiblesse du Pokemon est d??j?? une force ou du m??me type.';
    END IF;
END //

CREATE TRIGGER pokemon_verifier_force
    BEFORE INSERT
    ON `Force`
    FOR EACH ROW
BEGIN
    DECLARE est_une_faiblesse INTEGER UNSIGNED;
    DECLARE est_de_type INTEGER UNSIGNED;

    SELECT COUNT(*) INTO est_une_faiblesse FROM `Faiblesse` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    SELECT COUNT(*) INTO est_de_type FROM `Typage` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    IF est_une_faiblesse > 0 OR est_de_type > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La force du Pokemon est d??j?? une faiblesse ou du m??me type.';
    END IF;
END //

CREATE TRIGGER pokemon_verifier_typage
    BEFORE INSERT
    ON `Typage`
    FOR EACH ROW
BEGIN
    DECLARE est_une_force INTEGER UNSIGNED;
    DECLARE est_une_faiblesse INTEGER UNSIGNED;

    SELECT COUNT(*) INTO est_une_faiblesse FROM `Faiblesse` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    SELECT COUNT(*) INTO est_une_force FROM `Force` WHERE Type = new.Type AND IdPokemon = new.IdPokemon;
    IF est_une_faiblesse > 0 OR est_une_force > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le typage du Pokemon est d??j?? une faiblesse ou uen force.';
    END IF;
END //

CREATE TRIGGER pokemon_verifier_attaque
    BEFORE INSERT
    ON Attaque
    FOR EACH ROW
BEGIN
    DECLARE est_une_faiblesse INTEGER UNSIGNED;

    SELECT COUNT(*)
    INTO est_une_faiblesse
    FROM `Faiblesse`
    WHERE Type = (SELECT Specialisation FROM Technique WHERE Intitule = new.Technique)
      AND IdPokemon = new.IdPokemon;
    IF est_une_faiblesse > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le Pok??mon ne peut pas apprendre une attaque du m??me type qu\'une faiblesse.';
    END IF;
END //

DELIMITER ;

/* Vues */
CREATE VIEW pokemon_with_mega AS
SELECT Pokemon.Id, Pokemon.Nom
FROM Pokemon
WHERE Pokemon.Mega = TRUE;

CREATE VIEW fully_evolved_pokemon AS
SELECT Pokemon.Id, Pokemon.Nom
FROM Pokemon
WHERE Pokemon.Evolution IS NULL;

CREATE VIEW Hoenn_Only AS
SELECT *
FROM Pokemon
         INNER JOIN Localisation ON
    Pokemon.Id = Localisation.IdPokemon
WHERE Localisation.Region = "Hoenn";

CREATE VIEW Johto_Only AS
SELECT *
FROM Pokemon
         INNER JOIN Localisation ON
    Pokemon.Id = Localisation.IdPokemon
WHERE Localisation.Region = "Johto";

CREATE VIEW Kalos_Only AS
SELECT *
FROM Pokemon
         INNER JOIN Localisation ON
    Pokemon.Id = Localisation.IdPokemon
WHERE Localisation.Region = "Kalos";

CREATE VIEW Sinnoh_Only AS
SELECT *
FROM Pokemon
         INNER JOIN Localisation ON
    Pokemon.Id = Localisation.IdPokemon
WHERE Localisation.Region = "Sinnoh";

CREATE VIEW Unys_Only AS
SELECT *
FROM Pokemon
         INNER JOIN Localisation ON
    Pokemon.Id = Localisation.IdPokemon
WHERE Localisation.Region = "Unys";

CREATE VIEW Water_Only AS
SELECT Id, Nom 
FROM Pokemon 
        INNER JOIN Typage ON 
    Pokemon.Id = Typage.IdPokemon
WHERE Type = "Eau";

CREATE VIEW Fire_Only AS
SELECT Id, Nom 
FROM Pokemon 
        INNER JOIN Typage ON 
    Id = IdPokemon
WHERE Type = "Feu";

CREATE VIEW Plant_Only AS
SELECT Id, Nom 
FROM Pokemon 
        INNER JOIN Typage 
    ON Id = IdPokemon
WHERE Type = "Plante";

CREATE VIEW Flame_thrower AS
SELECT Id, Nom 
FROM Pokemon 
        INNER JOIN Attaque 
    ON Id = IdPokemon
WHERE Technique = "Lance-Flammes"

/* Droits */
CREATE ROLE IF NOT EXISTS 'HoennFan', 'JohtoFan', 'KalosFan', 'SinnohFan', 'UnysFan', 'PokeMaster', 'App';

GRANT ALL ON pokedb.* TO 'PokeMaster';
GRANT SELECT ON pokedb.* TO 'App';
GRANT SELECT ON pokedb.pokemon_with_mega TO UnysFan;
GRANT SELECT ON pokedb.fully_evolved_pokemon TO UnysFan;
GRANT SELECT ON pokedb.Unys_Only TO UnysFan;
GRANT SELECT ON pokedb.Sinnoh_Only TO SinnohFan;
GRANT SELECT ON pokedb.Kalos_Only TO KalosFan;
GRANT SELECT ON pokedb.Johto_Only TO JohtoFan;
GRANT SELECT ON pokedb.Hoenn_Only TO HoennFan;
GRANT EXECUTE ON PROCEDURE pokedb.pokemon_actualiser_evolution TO UnysFan;
GRANT EXECUTE ON PROCEDURE pokedb.pokemon_definir_localisation TO UnysFan;

CREATE USER IF NOT EXISTS sam@'%' IDENTIFIED BY "sam123";
CREATE USER IF NOT EXISTS tom@'%' IDENTIFIED BY "tom123";
CREATE USER IF NOT EXISTS pete@'%' IDENTIFIED BY "pete123";
CREATE USER IF NOT EXISTS bob@'%' IDENTIFIED BY "bob123";
CREATE USER IF NOT EXISTS luis@'%' IDENTIFIED BY "luis123";
CREATE USER IF NOT EXISTS ross@'%' IDENTIFIED BY "ross123";
CREATE USER IF NOT EXISTS john@'%' IDENTIFIED BY "john123";
CREATE USER IF NOT EXISTS ashe@'%' IDENTIFIED BY "ashe123";
CREATE USER IF NOT EXISTS will@'%' IDENTIFIED BY "will123";
CREATE USER IF NOT EXISTS alan@'%' IDENTIFIED BY "alan123";
CREATE USER IF NOT EXISTS pokecli@'%' IDENTIFIED BY "pokecli123";

GRANT UnysFan TO sam@'%';
GRANT UnysFan TO tom@'%';
GRANT PokeMaster TO pete@'%';
GRANT PokeMaster TO bob@'%';
GRANT JohtoFan TO luis@'%';
GRANT JohtoFan TO ross@'%';
GRANT KalosFan TO john@'%';
GRANT KalosFan TO ashe@'%';
GRANT SinnohFan TO will@'%';
GRANT SinnohFan TO alan@'%';
GRANT App TO pokecli@'%';

SET DEFAULT ROLE ALL TO
    sam@'%',
    tom@'%',
    pete@'%',
    bob@'%',
    luis@'%',
    ross@'%',
    john@'%',
    ashe@'%',
    will@'%',
    alan@'%',
    pokecli@'%';

/* Data */

INSERT INTO Type(Intitule)
VALUES ("???"),
       ("Acier"),
       ("Bird"),
       ("Combat"),
       ("Dragon"),
       ("Eau"),
       ("Feu"),
       ("F??e"),
       ("Glace"),
       ("Inconnu"),
       ("Insecte"),
       ("Normal"),
       ("Obscur"),
       ("Plante"),
       ("Poison"),
       ("Psy"),
       ("Roche"),
       ("Sol"),
       ("Spectre"),
       ("T??n??bres"),
       ("Vol"),
       ("??lectrik");

INSERT INTO Sexe(Intitule)
VALUES ("M??le"),
       ("Femelle");

INSERT INTO Route(Numero)
VALUES (1),
       (2),
       (3),
       (4),
       (5),
       (6),
       (7),
       (8),
       (9),
       (10),
       (11),
       (12),
       (13),
       (14),
       (15),
       (16),
       (17),
       (18),
       (19),
       (20),
       (21),
       (22),
       (23),
       (24),
       (25),
       (26),
       (27),
       (28),
       (29),
       (30),
       (31),
       (32),
       (33),
       (34),
       (35),
       (36),
       (37),
       (38),
       (39),
       (40),
       (41),
       (42),
       (43),
       (44),
       (45),
       (46),
       (47),
       (48),
       (62),
       (80),
       (81),
       (82),
       (83),
       (84),
       (85),
       (86),
       (87),
       (88),
       (89),
       (90),
       (95),
       (96),
       (97),
       (98),
       (99),
       (100),
       (101),
       (102),
       (103),
       (104),
       (105),
       (106),
       (107),
       (108),
       (109),
       (110),
       (111),
       (112),
       (113),
       (114),
       (115),
       (116),
       (117),
       (118),
       (119),
       (120),
       (121),
       (123),
       (125),
       (126),
       (127),
       (128),
       (133),
       (134),
       (138),
       (139),
       (145),
       (146),
       (147),
       (148),
       (150),
       (151),
       (153),
       (154),
       (155),
       (196),
       (201),
       (202),
       (203),
       (204),
       (205),
       (206),
       (207),
       (208),
       (209),
       (210),
       (211),
       (212),
       (213),
       (214),
       (215),
       (216),
       (217),
       (218),
       (219),
       (221),
       (222),
       (223),
       (224),
       (225),
       (227),
       (228),
       (229),
       (231),
       (232),
       (233),
       (234),
       (235),
       (236),
       (237),
       (238),
       (239),
       (248),
       (249),
       (282),
       (283);

INSERT INTO Region
VALUES ("Almia"),
       ("Alola"),
       ("Archipel Orange"),
       ("Ferrum"),
       ("Fiore"),
       ("Galar"),
       ("Hoenn"),
       ("Holon"),
       ("??les D??colores"),
       ("??les Sevii"),
       ("Johto"),
       ("Kalos"),
       ("Kanto"),
       ("Oblivia"),
       ("Passio"),
       ("Pays Pok??mon"),
       ("Pok??topia"),
       ("Rhode"),
       ("Sinnoh"),
       ("TCG Island"),
       ("Unys"),
       ("??le Carmonte");

INSERT INTO Categorie
VALUES ("ADN"),
       ("Acclameur"),
       ("Agent Secre"),
       ("Aiglon"),
       ("Ailes Pomme"),
       ("Aimant"),
       ("Alliage"),
       ("Allong??"),
       ("Alpha"),
       ("Annihilatio"),
       ("Antenne"),
       ("Appel"),
       ("Apprenti"),
       ("Aquabelette"),
       ("Aquabulle"),
       ("Aqualapin"),
       ("Aqualimace"),
       ("Aquaplante"),
       ("Aquasouris"),
       ("Araclectrik"),
       ("Arbregel??"),
       ("Arc-en-ciel"),
       ("Ardent"),
       ("Armoiseau"),
       ("Armure"),
       ("Art Martial"),
       ("Artificiel"),
       ("Artificier"),
       ("Assemblage"),
       ("Attachant"),
       ("Audition"),
       ("Aura"),
       ("Aurore"),
       ("Avaltouron"),
       ("Bisou"),
       ("Bonheur"),
       ("Bouboule"),
       ("Buffle"),
       ("Carapace"),
       ("Chamallot"),
       ("Cocon"),
       ("Debugant"),
       ("Empereur"),
       ("Endurant"),
       ("Enflamm??"),
       ("Enfl??"),
       ("Engrenage"),
       ("Enneigement"),
       ("Entra??nemen"),
       ("Escadron"),
       ("Escargot"),
       ("Espion"),
       ("Estomac"),
       ("Exhal??caill"),
       ("Explosion"),
       ("Exuviateur"),
       ("Exuvie"),
       ("Flamme"),
       ("F??e"),
       ("Gard'os"),
       ("Garnement"),
       ("Gaz Mortel"),
       ("Gaz"),
       ("Gel??"),
       ("Giga"),
       ("Gigoteur"),
       ("Glaciaire"),
       ("Glaive"),
       ("Gland"),
       ("Gla??on"),
       ("Goinfre"),
       ("Golem Ancie"),
       ("Gonflette"),
       ("Goulu"),
       ("Gracile"),
       ("Graine ??pin"),
       ("Graine"),
       ("Grand Sage"),
       ("Gratitude"),
       ("Grenouille"),
       ("Grifac??r??e"),
       ("Grincedent"),
       ("Grochon Feu"),
       ("Grosse Voix"),
       ("Grotte"),
       ("Gr??le"),
       ("Guind??"),
       ("Gu??poison"),
       ("G??n??rateur"),
       ("G??n??tique"),
       ("Halo Lunair"),
       ("Halo Solair"),
       ("Herbe"),
       ("Hibernant"),
       ("Hibou"),
       ("Hippo"),
       ("Hirondelle"),
       ("Holothurie"),
       ("Humano??de"),
       ("Hypnose"),
       ("Imitation"),
       ("Implacable"),
       ("Insectopic"),
       ("Insouciant"),
       ("Interdit"),
       ("Intimidatio"),
       ("Invitation"),
       ("Jardin"),
       ("Jet d'Eau"),
       ("Jet"),
       ("Joufflu"),
       ("Jovial"),
       ("Joyau"),
       ("Judo"),
       ("Jujitsu"),
       ("Jus Pomme"),
       ("Laine"),
       ("Lame"),
       ("Lampe"),
       ("Lance ?? Eau"),
       ("Lapidicole"),
       ("Lapin"),
       ("Larve"),
       ("Latteur"),
       ("Lave"),
       ("Libellogre"),
       ("Lionceau"),
       ("Lis d'Eau"),
       ("Lithicole"),
       ("Livraison"),
       ("Long-Cou"),
       ("Long-Nez"),
       ("Long-Patte"),
       ("Longqueue"),
       ("Long??vit??"),
       ("Loup"),
       ("Loutre"),
       ("Luciole"),
       ("Luminaire"),
       ("Luminescent"),
       ("Lumi??re"),
       ("Lunaire"),
       ("Lune"),
       ("L??cheur"),
       ("L??gendaire"),
       ("L??pid??caill"),
       ("L??zard"),
       ("L??zard'Eau"),
       ("Magique"),
       ("Magnanime"),
       ("Magn??tique"),
       ("Magouilleur"),
       ("Mainpince"),
       ("Maisonjouet"),
       ("Majestueux"),
       ("Malin"),
       ("Malveillant"),
       ("Manger??ve"),
       ("Mante"),
       ("Manteau"),
       ("Maresurfeur"),
       ("Marionnette"),
       ("Maternel"),
       ("Maxi Corne"),
       ("Mer du Sud"),
       ("Mime"),
       ("Minerai"),
       ("Mini Ours"),
       ("Miniabeille"),
       ("Minifeuille"),
       ("Minioiseau"),
       ("Minipoisson"),
       ("Minirondel"),
       ("Minisouris"),
       ("Minitortue"),
       ("Minoiseau"),
       ("Mite Givre"),
       ("Mollusque"),
       ("Monocorne"),
       ("Monture"),
       ("Mordillage"),
       ("Morphing"),
       ("Morsure"),
       ("Mouette"),
       ("Moufette"),
       ("Mousseline"),
       ("Mouton"),
       ("Mue"),
       ("Multicolor"),
       ("Multig??nome"),
       ("Multipli??"),
       ("Muraille"),
       ("Mystique"),
       ("Myst??rieux"),
       ("M??choire"),
       ("M??ditation"),
       ("M??galithe"),
       ("M??gaplopode"),
       ("M??lodie"),
       ("M??t??ore"),
       ("M??t??orite"),
       ("Nid Pomme"),
       ("Ninja"),
       ("Noble Lame"),
       ("Noir R??el"),
       ("Noirtotal"),
       ("Nonchalant"),
       ("Note Musiqu"),
       ("Nouveau"),
       ("N??buleuse"),
       ("N??on"),
       ("Obscurit??"),
       ("Oisancien"),
       ("Oiseau"),
       ("Oiseaucoton"),
       ("Oiseaudo"),
       ("Ombre"),
       ("Ombrefuge"),
       ("Ondes"),
       ("Orage"),
       ("Otarie"),
       ("Oursin"),
       ("Papillon"),
       ("Perceur"),
       ("Poirier"),
       ("Puncheur"),
       ("Renard"),
       ("Tortue"),
       ("Vachalait"),
       ("Ver"),
       ("V??n??pic"),
       ("??me Errante"),
       ("??me"),
       ("??ne"),
       ("??cailles"),
       ("??charpe"),
       ("??crou"),
       ("??cur??lec"),
       ("??lectrique"),
       ("??lectrophor"),
       ("??manation"),
       ("??motion"),
       ("??on"),
       ("??pinarmure"),
       ("??pine"),
       ("??pouvantail"),
       ("??quilibre"),
       ("??ruption"),
       ("??tincelec"),
       ("??tincelle"),
       ("??toile"),
       ("??tourneau"),
       ("??treinte"),
       ("??volutif"),
       ("??uf");

INSERT INTO Ville
VALUES ("Bonport", "Almia"),
       ("Bourg-Chicore", "Almia"),
       ("Campement Froidur", "Almia"),
       ("Terruptive", "Almia"),
       ("Village Alorize", "Almia"),
       ("V??terville", "Almia"),
       ("Automnelle", "Fiore"),
       ("Bourg-l'Hiver", "Fiore"),
       ("??lot-??t??", "Fiore"),
       ("Printiville", "Fiore"),
       ("Algatia", "Hoenn"),
       ("Atalanopolis", "Hoenn"),
       ("Aut??quia", "Hoenn"),
       ("Bourg-en-Vol", "Hoenn"),
       ("Cimetronelle", "Hoenn"),
       ("Cl??menti-Ville", "Hoenn"),
       ("??pic??a", "Hoenn"),
       ("??ternara", "Hoenn"),
       ("Lavandia", "Hoenn"),
       ("M??rouville", "Hoenn"),
       ("Myokara", "Hoenn"),
       ("N??nucrique", "Hoenn"),
       ("Pacifiville", "Hoenn"),
       ("Poivressel", "Hoenn"),
       ("Riyadoville", "Hoenn"),
       ("Rosy??res", "Hoenn"),
       ("Rubello", "Hoenn"),
       ("Vergazon", "Hoenn"),
       ("Vermilava", "Hoenn"),
       ("Acajou", "Johto"),
       ("Bourg Geon", "Johto"),
       ("Doublonville", "Johto"),
       ("??b??nelle", "Johto"),
       ("??corcia", "Johto"),
       ("Irisia", "Johto"),
       ("Mauville", "Johto"),
       ("Noeunoeufville", "Johto"),
       ("Oliville", "Johto"),
       ("Rosalia", "Johto"),
       ("Ville Griotte", "Johto"),
       ("Argenta", "Kanto"),
       ("Azuria", "Kanto"),
       ("Bourg Palette", "Kanto"),
       ("Carmin sur Mer", "Kanto"),
       ("C??ladopole", "Kanto"),
       ("Cramois'??le", "Kanto"),
       ("Jadielle", "Kanto"),
       ("Lavanville", "Kanto"),
       ("Parmanie", "Kanto"),
       ("Safrania", "Kanto"),
       ("Salville", "Kanto"),
       ("Soleilville", "Kanto"),
       ("Terracotta", "Kanto"),
       ("Villedargent", "Kanto"),
       ("Ph??nacit", "Rhode"),
       ("Port Amarr??e", "Rhode"),
       ("Pyrite", "Rhode"),
       ("Samaragd", "Rhode"),
       ("Suerebe", "Rhode"),
       ("Aire de Combat", "Sinnoh"),
       ("Aire de D??tente", "Sinnoh"),
       ("Aire de Survie", "Sinnoh"),
       ("Bonaugure", "Sinnoh"),
       ("Bonville", "Sinnoh"),
       ("C??lestia", "Sinnoh"),
       ("Charbourg", "Sinnoh"),
       ("F??li-Cit??", "Sinnoh"),
       ("Floraville", "Sinnoh"),
       ("Frimapic", "Sinnoh"),
       ("Joliberges", "Sinnoh"),
       ("Ligue Pok??mon", "Sinnoh"),
       ("Littorella", "Sinnoh"),
       ("Rivamar", "Sinnoh"),
       ("Unionpolis", "Sinnoh"),
       ("Verchamps", "Sinnoh"),
       ("Vestigion", "Sinnoh"),
       ("Voilaroc", "Sinnoh");

INSERT INTO Technique
VALUES ("?? la Queue", "Retient la cible de force, l'obligeant ?? agir en dernier.", 0, 100, 15, "T??n??bres"),
       ("Abattage",
        "Le lanceur balaie violemment le camp adverse avec son immense queue. Baisse l'Attaque de la cible.", 60, 100,
        15, "Dragon"),
       ("Ab??me",
        "Le lanceur fait tomber l'ennemi dans une crevasse. Si cette attaque r??ussit, elle met K.O. sur le coup.", 1,
        30, 5, "Sol"),
       ("Aboiement", "Le lanceur hurle sur l'ennemi. Baisse l'Attaque Sp??ciale de l'ennemi.", 55, 95, 15, "T??n??bres"),
       ("Abri", "Le lanceur se prot??ge de toutes les attaques. Peut ??chouer si utilis??e plusieurs fois de suite.", 0, 0,
        10, "Normal"),
       ("Acidarmure", "Le lanceur modifie sa structure mol??culaire pour se liqu??fier et beaucoup augmenter sa D??fense.",
        0, 0, 20, "Poison"),
       ("Acide", "Le lanceur attaque l'ennemi avec un jet d'acide corrosif. Peut aussi baisser sa D??fense Sp??ciale.",
        40, 100, 30, "Poison"),
       ("Acide Malique",
        "Le lanceur attaque son adversaire avec un liquide corrosif cr???? ?? partir d'une pomme acide. Baisse la D??fense Sp??ciale de la cible.",
        80, 100, 10, "Plante"),
       ("Acrobatie", "Attaque agile. Si le lanceur ne tient pas d'objet, l'attaque inflige davantage de d??g??ts.", 55,
        100, 15, "Vol"),
       ("Acupression", "Le lanceur utilise sa connaissance des points de pression pour beaucoup augmenter une stat.", 0,
        0, 30, "Normal"),
       ("Aegis Maxima",
        "Le lanceur se transforme en un immense bouclier et charge son adversaire. Inflige le double de d??g??ts aux Pok??mon Dynamax.",
        100, 100, 5, "Acier"),
       ("A??roblast", "Le lanceur projette une tornade sur l'ennemi pour infliger des d??g??ts. Taux de critiques ??lev??.",
        100, 95, 5, "Vol"),
       ("A??romax",
        "Une attaque de type Vol que seuls les Pok??mon Dynamax peuvent utiliser. Augmente la Vitesse des alli??s.", 10,
        0, 10, "Vol"),
       ("A??ropique", "Le lanceur prend l'ennemi de vitesse et le lac??re. N'??choue jamais.", 60, 0, 20, "Vol"),
       ("Affilage", "Le lanceur se concentre pour ??tre s??r de porter un coup critique au tour suivant.", 0, 0, 30,
        "Normal"),
       ("Aff??tage", "R??duit les polygones et augmente l'ATTAQUE.", 0, 0, 30, "Normal"),
       ("Aiguisage", "Le lanceur s'aiguise les griffes. Augmente l'Attaque et la Pr??cision.", 0, 0, 15, "T??n??bres"),
       ("Ailes d'Acier",
        "Le lanceur frappe l'ennemi avec des ailes d'acier. Peut aussi augmenter la D??fense du lanceur.", 70, 90, 25,
        "Acier"),
       ("Air Veinard", "L'adversaire ne peut pas faire de coup critique pendant 5 tours", 0, 0, 30, "Normal"),
       ("Aire d'Eau",
        "Une masse d'eau s'abat sur l'ennemi. En l'utilisant avec Aire de Feu, l'effet augmente et un arc-en-ciel appara??t.",
        80, 100, 10, "Eau"),
       ("Aire d'Herbe",
        "Une masse v??g??tale s'abat sur l'ennemi. En l'utilisant avec Aire d'Eau, l'effet augmente et un mar??cage appara??t.",
        80, 100, 10, "Plante"),
       ("Aire de Feu",
        "Une masse de feu s'abat sur l'ennemi. En l'utilisant avec Aire d'Herbe, l'effet augmente et une mer de feu appara??t.",
        80, 100, 10, "Feu"),
       ("All??gement",
        "Le lanceur se d??barrasse des parties inutiles de son corps. Son poids diminue et sa Vitesse augmente beaucoup.",
        0, 0, 15, "Acier"),
       ("Amass'Sable",
        "Le lanceur r??cup??re jusqu'?? la moiti?? de ses PV max. Durant une temp??te de sable, il en r??cup??re encore plus.",
        0, 0, 10, "Sol"),
       ("Amn??sie",
        "Le lanceur fait le vide dans son esprit pour oublier ses soucis. Augmente beaucoup sa D??fense Sp??ciale.", 0, 0,
        20, "Psy"),
       ("Ampleur", "Un tremblement de terre d'intensit?? variable.", 1, 100, 30, "Sol"),
       ("Ancrage",
        "Le lanceur jette son ancre sur la cible pour l'attaquer. Une fois accroch??e, elle l'emp??che de s'enfuir.", 80,
        100, 20, "Acier"),
       ("Anneau Hydro", "Un voile d'eau recouvre le lanceur et r??g??n??re ses PV ?? chaque tour.", 0, 0, 20, "Eau"),
       ("Anti-Air", "Le lanceur jette toutes sortes de projectiles ?? un ennemi. Si ce dernier vole, il tombe au sol.",
        50, 100, 15, "Roche"),
       ("Anti-Brume",
        "Un grand coup de vent qui disperse la Protection ou le Mur Lumi??re de l'ennemi. Diminue aussi son Esquive.", 0,
        0, 15, "Vol"),
       ("Anti-Soin", "L'adversaire ne peut pas restaurer ses PV pendant 5 tours", 0, 100, 15, "Psy"),
       ("Charge", "Le lanceur charge l'ennemi et le percute de tout son poids.", 40, 1000, 35, "Normal"),
       ("Rugissement",
        "Le lanceur pousse un cri tout mimi pour tromper la vigilance de l'ennemi et baisser son Attaque.", 0, 100, 40,
        "Normal"),
       ("Fouet Lianes", "Fouette l'ennemi avec de fines lianes pour infliger des d??g??ts.", 45, 100, 25, "Plante"),
       ("Croissance", "Le corps du lanceur se d??veloppe. Augmente l'Attaque et l'Attaque Sp??ciale.", 0, 0, 20,
        "Normal"),
       ("Vampigraine",
        "Une graine est sem??e sur l'ennemi. ?? chaque tour, elle lui d??robe des PV que le lanceur r??cup??re.", 0, 90, 10,
        "Plante"),
       ("Tranch'Herbe", "Des feuilles aiguis??es comme des rasoirs entaillent l'ennemi. Taux de critiques ??lev??.", 55,
        95, 25, "Plante"),
       ("Poudre Dodo", "Le lanceur r??pand une poudre soporifique qui endort la cible.", 0, 75, 15, "Plante"),
       ("Poudre Toxik", "Une poudre toxique empoisonne l'ennemi.", 0, 75, 35, "Poison"),
       ("Canon Graine", "Le lanceur fait pleuvoir un d??luge de graines explosives sur l'ennemi.", 80, 100, 15,
        "Plante"),
       ("B??lier", "Une charge violente qui blesse aussi l??g??rement le lanceur.", 90, 85, 20, "Normal"),
       ("Doux Parfum", "L'attaque baisse l'esquive de l'adversaire d'un cran.", 0, 100, 20, "Normal"),
       ("Synth??se", "Un soin qui restaure des PV au lanceur. Son efficacit?? varie en fonction de la m??t??o.", 0, 0, 5,
        "Plante"),
       ("Soucigraine",
        "Plante sur la cible une graine qui la rend soucieuse et remplace son talent par Insomnia, l'emp??chant ainsi de dormir.",
        0, 100, 10, "Plante"),
       ("Damocl??s", "Une charge dangereuse et imprudente. Blesse aussi gravement le lanceur.", 120, 100, 15, "Normal"),
       ("Lance-Soleil", "Absorbe la lumi??re au premier tour et envoie un rayon puissant au tour suivant.", 120, 100, 10,
        "Plante"),
       ("Griffe", "Lac??re l'ennemi avec des griffes ac??r??es pour lui infliger des d??g??ts.", 40, 100, 35, "Normal"),
       ("Flamm??che", "L'ennemi est attaqu?? par une faible flamme. Peut aussi le br??ler.", 40, 100, 25, "Feu"),
       ("Brouillard", "Le lanceur disperse un nuage d'encre ou de fum??e. R??duit la Pr??cision de l'ennemi.", 0, 100, 20,
        "Normal"),
       ("Dracosouffle", "Le lanceur souffle fort sur l'ennemi pour lui infliger des d??g??ts. Peut aussi le paralyser.",
        60, 100, 20, "Dragon"),
       ("Crocs Feu", "Le lanceur utilise une morsure enflamm??e. Peut aussi br??ler ou apeurer l'ennemi.", 65, 95, 15,
        "Feu"),
       ("Tranche", "Un coup de griffe ou autre tranche l'ennemi. Taux de critiques ??lev??.", 70, 100, 20, "Normal"),
       ("Lance-Flammes", "L'ennemi re??oit un torrent de flammes. Peut aussi le br??ler.", 90, 100, 15, "Feu"),
       ("Grimace", "Le lanceur fait une grimace qui effraie l'ennemi et r??duit beaucoup sa Vitesse.", 0, 100, 10,
        "Normal"),
       ("Danse Flamme", "Un tourbillon de flammes emprisonne l'ennemi pendant quatre ?? cinq tours.", 35, 85, 15, "Feu"),
       ("Feu d'Enfer", "L'ennemi est entour?? d'un torrent de flammes ardentes qui le br??lent.", 100, 50, 5, "Feu"),
       ("Boutefeu",
        "Le lanceur s'embrase avant de charger l'ennemi. Le choc blesse aussi gravement le lanceur. Peut br??ler l'ennemi.",
        120, 100, 15, "Feu"),
       ("Mimi-Queue",
        "Le lanceur remue son adorable queue pour tromper la vigilance de l'ennemi et baisser sa D??fense.", 0, 100, 30,
        "Normal"),
       ("Pistolet ?? O", "De l'eau est projet??e avec force sur l'ennemi.", 40, 100, 25, "Eau"),
       ("Repli", "Le lanceur se recroqueville dans sa carapace, ce qui augmente sa D??fense.", 0, 0, 40, "Eau"),
       ("Tour Rapide",
        "Une attaque tournoyante pouvant aussi annuler, par exemple, ??treinte, Ligotage ou Vampigraine. Augmente ??galement la Vitesse du lanceur.",
        50, 100, 40, "Normal"),
       ("Morsure", "L'ennemi est mordu par de tranchantes canines. Peut l'apeurer.", 60, 100, 25, "T??n??bres"),
       ("Vibraqua", "Le lanceur envoie un puissant jet d'eau sur l'ennemi. Peut le rendre confus.", 60, 100, 20, "Eau"),
       ("Hydroqueue", "Le lanceur attaque en balan??ant sa queue comme une lame de fond en pleine temp??te.", 90, 90, 10,
        "Eau"),
       ("Exuviation",
        "Le lanceur brise sa coquille. Il baisse sa D??fense et sa D??fense Sp??ciale, mais augmente beaucoup son Attaque, son Attaque Sp??ciale et sa Vitesse.",
        0, 0, 15, "Normal"),
       ("Hydrocanon", "Un puissant jet d'eau est dirig?? sur l'ennemi.", 110, 80, 5, "Eau"),
       ("S??cr??tion", "Le lanceur crache de la soie pour ligoter l'ennemi et beaucoup baisser sa Vitesse.", 0, 95, 40,
        "Insecte"),
       ("Piq??re", "Le lanceur pique l'ennemi. Si ce dernier tient une Baie, le lanceur la d??vore et obtient son effet.",
        60, 100, 20, "Insecte"),
       ("Armure", "Le lanceur contracte tous ses muscles pour augmenter sa D??fense.", 0, 0, 30, "Normal"),
       ("Tornade", "Le lanceur bat des ailes pour g??n??rer une bourrasque qui blesse l'ennemi.", 40, 100, 35, "Vol"),
       ("Ultrason", "Le lanceur produit d'??tranges ondes sonores qui rendent la cible confuse.", 0, 55, 20, "Normal"),
       ("Cyclone",
        "??jecte le Pok??mon ennemi et le remplace par un autre. Lors d'un combat contre un Pok??mon sauvage seul, met fin au combat.",
        0, 0, 20, "Normal"),
       ("Lame d'Air", "Le lanceur attaque avec une lame d'air qui fend tout. Peut aussi apeurer l'ennemi.", 75, 95, 15,
        "Vol"),
       ("Dard-Venin", "Un dard toxique qui transperce l'ennemi. Peut aussi l'empoisonner.", 15, 100, 35, "Poison"),
       ("Double-Dard", "Les dards des pattes avant frappent deux fois.", 25, 100, 20, "Insecte"),
       ("Furie", "Frappe l'ennemi deux ?? cinq fois d'affil??e avec un bec ou une corne, par exemple.", 15, 85, 20,
        "Normal"),
       ("Fr??n??sie", "Augmente l'Attaque du lanceur d'un niveau ?? chaque coup re??u.", 20, 100, 20, "Normal"),
       ("Poursuite", "Inflige de s??rieux d??g??ts lorsque l'ennemi change.", 40, 100, 20, "T??n??bres"),
       ("Puissance", "Le lanceur prend une profonde inspiration et se concentre pour augmenter son taux de critiques.",
        0, 0, 30, "Normal"),
       ("Effort", "Une attaque qui r??duit les PV de l'ennemi au niveau des PV du lanceur.", 1, 100, 5, "Normal"),
       ("Jet de Sable", "Lance du sable au visage de l'ennemi pour baisser sa Pr??cision.", 0, 100, 15, "Sol"),
       ("Vive-Attaque",
        "Le lanceur fonce sur l'ennemi si rapidement qu'on parvient ?? peine ?? le discerner. Frappe en priorit??.", 40,
        100, 30, "Normal"),
       ("Ouragan", "D??clenche un terrible ouragan sur l'ennemi. Peut aussi l'apeurer.", 40, 100, 20, "Dragon"),
       ("H??te", "Le lanceur se relaxe et all??ge son corps pour beaucoup augmenter sa Vitesse.", 0, 0, 30, "Psy"),
       ("Charme", "Le lanceur fait les yeux doux pour berner l'ennemi et beaucoup r??duire son Attaque.", 0, 100, 20,
        "F??e"),
       ("Encore", "Oblige l'ennemi ?? r??p??ter la derni??re capacit?? utilis??e durant trois tours.", 0, 100, 5, "Normal"),
       ("Gravit??",
        "Pendant cinq tours, les Pok??mon Vol ou qui ont L??vitation deviennent sensibles aux capacit??s Sol, et les capacit??s volantes deviennent inutilisables.",
        0, 0, 5, "Psy"),
       ("M??tronome",
        "Le lanceur agite un doigt et stimule son cerveau pour utiliser presque n'importe quelle capacit?? au hasard.",
        0, 0, 10, "Normal"),
       ("Lilliput", "Le lanceur comprime son corps pour se faire tout petit et beaucoup augmenter son Esquive.", 0, 0,
        10, "Normal"),
       ("Rayon Lune", "Un soin qui restaure des PV au lanceur. Son efficacit?? varie en fonction de la m??t??o.", 0, 0, 5,
        "F??e"),
       ("V??u Soin", "Le lanceur tombe K.O. pour soigner les PV et le statut du Pok??mon qui passe apr??s lui.", 0, 0, 10,
        "Psy"),
       ("Calcination",
        "Des flammes calcinent l'ennemi. S'il tient un objet, une Baie par exemple, celui-ci est br??l?? et devient inutilisable.",
        60, 100, 15, "Feu"),
       ("Berceuse", "Une berceuse plonge l'ennemi dans un profond sommeil.", 0, 55, 15, "Normal"),
       ("Boul'Armure", "Le lanceur s'enroule pour cacher ses points faibles, ce qui augmente sa D??fense.", 0, 0, 040,
        "Normal"),
       ("Entrave", "Emp??che l'ennemi d'employer ?? nouveau sa derni??re attaque. Dure quatre tours.", 0, 100, 20,
        "Normal"),
       ("Torgnoles", "Gifle rapidement l'ennemi de 2 ?? 5 fois.", 15, 85, 10, "Normal"),
       ("Roulade", "Un rocher roule sur l'ennemi pendant cinq tours. L'attaque gagne en puissance ?? chaque coup.", 30,
        90, 20, "Roche"),
       ("Avale", "Le lanceur absorbe la puissance accumul??e avec Stockage pour restaurer ses PV.", 0, 0, 10, "Normal"),
       ("Stockage",
        "Le lanceur accumule de la puissance et augmente sa D??fense et sa D??fense Sp??ciale. Peut ??tre utilis??e trois fois.",
        0, 0, 20, "Normal"),
       ("Repos", "Le lanceur regagne tous ses PV et soigne ses alt??rations de statut, puis il dort pendant deux tours.",
        0, 0, 10, "Psy"),
       ("Copie",
        "Le lanceur copie la derni??re capacit?? utilis??e par la cible et la conserve tant qu'il reste au combat.", 0, 0,
        10, "Normal"),
       ("M??gaphone", "Le lanceur pousse un cri dont l'??cho terrifiant a le pouvoir d'infliger des d??g??ts ?? l'ennemi.",
        90, 100, 10, "Normal"),
       ("??cras'Face", "??crase l'ennemi avec les pattes avant ou la queue, par exemple.", 40, 100, 35, "Normal"),
       ("Trempette", "Le lanceur barbote et ??clabousse les environs. Cette capacit?? n'a aucun effet.", 0, 0, 40,
        "Normal"),
       ("Doux Baiser", "Le lanceur envoie un bisou si mignon et d??sarmant qu'il plonge l'ennemi dans la confusion.", 0,
        75, 10, "F??e"),
       ("Picpic", "Frappe l'ennemi d'un bec pointu ou d'une corne pour infliger des d??g??ts.", 35, 100, 35, "Vol"),
       ("Double Pied", "Deux coups de pied qui frappent l'ennemi deux fois d'affil??e.", 30, 100, 30, "Combat"),
       ("Koud'Korne", "Frappe l'ennemi d'un coup de corne pointue pour infliger des d??g??ts.", 65, 100, 25, "Normal"),
       ("Flatterie", "Rend la cible confuse, mais augmente son Attaque Sp??ciale.", 0, 100, 15, "T??n??bres"),
       ("Mania", "Une attaque furieuse qui dure de deux ?? trois tours. Le lanceur devient confus.", 120, 100, 10,
        "Normal"),
       ("M??gacorne", "Le lanceur utilise ses gigantesques cornes pour charger l'ennemi.", 120, 85, 10, "Insecte"),
       ("Ruse",
        "Une attaque capable de toucher un ennemi qui utilise une capacit?? comme D??tection ou Abri. Annule l'effet de ces capacit??s.",
        30, 100, 10, "Normal"),
       ("Vendetta", "Une attaque deux fois plus puissante si le lanceur a ??t?? bless?? par l'ennemi durant ce tour.", 60,
        100, 10, "Combat"),
       ("Balayage", "Un puissant coup de pied bas qui fauche l'ennemi. Il est plus efficace contre les ennemis lourds.",
        1, 100, 20, "Combat"),
       ("Bluff", "Permet de frapper en priorit?? et apeure l'ennemi. Ne fonctionne qu'au premier tour.", 40, 100, 10,
        "Normal"),
       ("Coup d'Main", "Une capacit?? qui augmente la puissance d'attaque d'un alli??.", 0, 0, 20, "Normal"),
       ("Reflet", "Le lanceur se d??place si vite qu'il cr??e des copies illusoires de lui-m??me, augmentant son Esquive.",
        0, 0, 15, "Normal"),
       ("Flash", "Explosion lumineuse qui fait baisser la pr??cision.", 0, 100, 20, "Normal"),
       ("Attrition",
        "Une attaque puissante quand l???ennemi baisse sa garde. Inflige des d??g??ts sans tenir compte des changements de stats.",
        70, 100, 20, "Normal"),
       ("L??chouille", "Un grand coup de langue qui inflige des d??g??ts ?? l'ennemi. Peut aussi le paralyser.", 30, 100,
        30, "Spectre"),
       ("Requiem", "Tout Pok??mon qui entend ce requiem est K.O. dans trois tours ?? moins qu'il ne soit remplac??.", 0, 0,
        5, "Normal"),
       ("Blizzard", "Une violente temp??te de neige s'abat sur l'ennemi. Peut aussi le geler.", 110, 70, 5, "Glace"),
       ("Psyko", "Une puissante force t??l??kin??tique frappe l'ennemi. Peut aussi faire baisser sa D??fense Sp??ciale.", 90,
        100, 10, "Psy"),
       ("Patience", "Encaisse les attaques sur 2 tours et renvoie le double.", 1, 0, 10, "Normal"),
       ("Plaquage", "Le lanceur se laisse tomber sur l'ennemi de tout son poids. Peut aussi le paralyser.", 85, 100, 15,
        "Normal"),
       ("Dracochoc", "Le lanceur ouvre la bouche pour envoyer une onde de choc qui frappe l'ennemi.", 85, 100, 10,
        "Dragon");

INSERT INTO Pokemon (Id, Nom, Description, Taille, Poids, ExperienceMinimum, ExperienceMaximum)
VALUES (1, "Bulbizarre",
        "Bulbizarre passe son temps ?? faire la sieste sous le soleil. Il y a une graine sur son dos. Il absorbe les rayons du soleil pour faire doucement pousser la graine.",
        0.7, 6.9, 64, 1059860),
       (2, "Herbizarre",
        "Un bourgeon a pouss?? sur le dos de ce Pok??mon. Pour en supporter le poids, Herbizarre a d?? se muscler les pattes. Lorsqu'il commence ?? se pr??lasser au soleil, ??a signifie que son bourgeon va ??clore, donnant naissance ?? une fleur.",
        1.0, 13.0, 141, 1059860),
       (3, "Florizarre",
        "Une belle fleur se trouve sur le dos de Florizarre. Elle prend une couleur vive lorsqu'elle est bien nourrie et bien ensoleill??e. Le parfum de cette fleur peut apaiser les gens.",
        2.0, 100.0, 236, 1059860),
       (301, "M??ga-Florizarre",
        "M??ga-Florizarre a un feuillage plus d??velopp??. Son dos est recouvert de feuilles et d'un tronc qui est plus ??lev?? avec une grande fleur qui s'??panouit ?? son sommet.",
        2.4, 155.5, 208, 1059860),
       (4, "Salam??che",
        "La flamme qui br??le au bout de sa queue indique l'humeur de ce Pok??mon. Elle vacille lorsque Salam??ch est content. En revanche, lorsqu'il s'??nerve, la flamme prend de l'importance et br??le plus ardemment.",
        0.6, 8.5, 65, 1059860),
       (5, "Reptincel",
        "Reptincel lac??re ses ennemis sans piti?? gr??ce ?? ses griffes ac??r??es. S'il rencontre un ennemi puissant, il devient agressif et la flamme au bout de sa queue s'embrase et prend une couleur bleu clair.",
        1.1, 19, 142, 1059860),
       (6, "Dracaufeu",
        "Reptincel lac??re ses ennemis sans piti?? gr??ce ?? ses griffes ac??r??es. S'il rencontre un ennemi puissant, il devient agressif et la flamme au bout de sa queue s'embrase et prend une couleur bleu clair.",
        1.7, 90.5, 209, 1059860),
       (7, "Carapuce",
        "La carapace de Carapuce ne sert pas qu'?? le prot??ger. La forme ronde de sa carapace et ses rainures lui permettent d'am??liorer son hydrodynamisme. Ce Pok??mon nage extr??mement vite.",
        0.5, 9.0, 66, 1059860),
       (8, "Carabaffe",
        "Carabaffe a une large queue recouverte d'une ??paisse fourrure. Elle devient de plus en plus fonc??e avec l'??ge. Les ??raflures sur la carapace de ce Pok??mon t??moignent de son exp??rience au combat.",
        1, 22.5, 143, 1059860),
       (9, "Tortank",
        "Tortank dispose de canons ?? eau ??mergeant de sa carapace. Ils sont tr??s pr??cis et peuvent envoyer des balles d'eau capables de faire mouche sur une cible situ??e ?? plus de 50 m.",
        1.6, 85.5, 210, 1059860),
       (10, "Chenipan",
        "Chenipan a un app??tit d'ogre. Il peut engloutir des feuilles plus grosses que lui. Les antennes de ce Pok??mon d??gagent une odeur particuli??rement ent??tante.",
        0.3, 2.9, 53, 1000000),
       (11, "Chrysacier",
        "La carapace prot??geant ce Pok??mon est dure comme du m??tal. Chrysacier ne bouge pas beaucoup. Il reste immobile pour pr??parer les organes ?? l'int??rieur de sa carapace en vue d'une ??volution future.",
        0.7, 9.9, 72, 1000000),
       (12, "Papilusion",
        "Papilusion est tr??s dou?? pour rep??rer le d??licieux nectar qu'il butine dans les fleurs. Il peut d??tecter, extraire et transporter le nectar de fleurs situ??es ?? plus de 10 km de son nid.",
        1.1, 32.0, 160, 1000000),
       (13, "Aspicot",
        "L'odorat d'Aspicot est extr??mement d??velopp??. Il lui suffit de renifler ses feuilles pr??f??r??es avec son gros appendice nasal pour les reconna??tre entre mille.",
        0.3, 3.2, 52, 1000000),
       (14, "Coconfort",
        "Coconfort est la plupart du temps immobile et reste accroch?? ?? un arbre. Cependant, int??rieurement, il est tr??s actif, car il se pr??pare pour sa prochaine ??volution. En touchant sa carapace, on peut sentir sa chaleur.",
        0.6, 10.0, 71, 1000000),
       (15, "Dardargnan",
        "Dardargnan est extr??mement possessif. Il vaut mieux ne pas toucher ?? son nid si on veut ??viter d'avoir des ennuis. Lorsqu'ils sont en col??re, ces Pok??mon attaquent en masse.",
        1.0, 29.5, 159, 1000000),
       (16, "Roucool",
        "Roucool a un excellent sens de l'orientation. Il est capable de retrouver son nid sans jamais se tromper, m??me s'il est tr??s loin de chez lui et dans un environnement qu'il ne conna??t pas.",
        0.3, 1.8, 55, 1059860),
       (17, "Roucoups",
        "Roucoups utilise une vaste surface pour son territoire. Ce Pok??mon surveille r??guli??rement son espace a??rien. Si quelqu'un p??n??tre sur son territoire, il corrige l'ennemi sans piti?? d'un coup de ses terribles serres.",
        1.1, 30.0, 113, 1059860),
       (18, "Roucarnage",
        "Ce Pok??mon est dot?? d'un plumage magnifique et luisant. Bien des Dresseurs sont captiv??s par la beaut?? fatale de sa huppe et d??cident de choisir Roucarnage comme leur Pok??mon favori.",
        1.5, 39.5, 172, 1059860),
       (35, "M??lof??e",
        "Les nuits de pleine lune, des groupes de ces Pok??mon sortent jouer. Lorsque l'aube commence ?? poindre, les M??lof??e fatigu??s rentrent dans leur retraite montagneuse et vont dormir, blottis les uns contre les autres.",
        0.6, 7.5, 68, 800000),
       (36, "M??lodelfe",
        "Les M??lodelfe se d??placent en sautant doucement, comme s'ils volaient. Leur d??marche l??g??re leur permet m??me de marcher sur l'eau. On raconte qu'ils se prom??nent sur les lacs, les soirs o?? la lune est claire.",
        1.3, 40.0, 129, 800000),
       (37, "Goupix",
        "?? sa naissance, Goupix a une queue blanche. Cette queue se divise en six si le Pok??mon re??oit de l'amiti?? de la part de son Dresseur. Les six queues sont courb??es et magnifiques.",
        0.6, 9.9, 63, 1000000),
       (371, "Goupix d'Alola",
        "La temp??rature de son souffle descend ?? -50 ??C. Les anciens d'Alola l'appellent encore par son ancien nom : ?? Ke'oke'o ??.",
        0.6, 9.9, 60, 1000000),
       (38, "Feunard",
        "Feunard peut envoyer un inqui??tant rayon avec ses yeux rouge vif pour prendre le contr??le de l'esprit de son ennemi. On raconte que ce Pok??mon peut vivre 1 000 ans.",
        1.1, 19.9, 177, 1000000),
       (381, "Feunard d'Alola",
        "Il fait de petites boules de glace avec sa fourrure et en canarde son adversaire. Quand il s'??nerve, il peut le congeler sur place.",
        1.1, 19.9, 178, 1000000),
       (39, "Rondoudou",
        "Rondoudou utilise ses cordes vocales pour ajuster librement la longueur d'onde de sa voix. Cela permet ?? ce Pok??mon de chanter en utilisant une longueur d'onde qui endort ses ennemis.",
        0.5, 5.5, 76, 800000),
       (40, "Grodoudou",
        "Grodoudou a des yeux immenses et ??carquill??s. La surface de ses yeux est couverte d'une fine couche de larmes. Si de la poussi??re est projet??e dans les yeux de ce Pok??mon, elle est rapidement ??vacu??e.",
        1.0, 12.0, 109, 800000),
       (173, "M??lo",
        "Les nuits o?? il y a des ??toiles filantes, on peut voir des M??lo danser en cercle. Ils dansent toute la nuit et ne s'arr??tent qu'?? l'aube. Ces Pok??mon se d??salt??rent alors avec la ros??e du matin.",
        0.3, 3.0, 37, 800000),
       (174, "Toudoudou",
        "Les cordes vocales de Toudoudou ne sont pas assez d??velopp??es. S'il devait chanter trop longtemps, il se ferait mal ?? la gorge. Ce Pok??mon se gargarise souvent avec de l'eau fra??che puis??e dans un ruisseau clair.",
        0.3, 1.0, 39, 800000),
       (32, "Nidoran???",
        "Nidoran??? a d??velopp?? des muscles pour bouger ses oreilles. Ainsi, il peut les orienter ?? sa guise. Ce Pok??mon peut entendre le plus discret des bruits.",
        0.5, 9.0, 60, 1059860),
       (33, "Nidorino",
        "Nidorino dispose d'une corne plus dure que du diamant. S'il sent une pr??sence hostile, toutes les pointes de son dos se h??rissent d'un coup, puis il d??fie son ennemi.",
        0.9, 19.5, 118, 1059860),
       (34, "Nidoking",
        "L'??paisse queue de Nidoking est d'une puissance incroyable. En un seul coup, il peut renverser une tour m??tallique. Lorsque ce Pok??mon se d??cha??ne, plus rien ne peut l'arr??ter.",
        1.4, 62.0, 195, 1059860),
       (106, "Kicklee",
        "Les jambes de Kicklee peuvent se contracter et s'??tirer ?? volont??. Gr??ce ?? ces jambes ?? ressort, il terrasse ses ennemis en les rouant de coups de pied. Apr??s les combats, il masse ses jambes pour ??viter de sentir la fatigue.",
        1.5, 49.8, 139, 1000000),
       (107, "Tygnon",
        "On raconte que Tygnon dispose de l'??tat d'esprit d'un boxeur qui s???entra??ne pour le championnat du monde. Ce Pok??mon est dot?? d'une t??nacit?? ?? toute ??preuve et n'abandonne jamais face ?? l'adversit??.",
        1.4, 50.2, 140, 1000000),
       (128, "Tauros",
        "Ce Pok??mon n'est pas satisfait s'il ne d??truit pas tout sur son passage. Lorsque Tauros ne trouve pas d'adversaire, il se rue sur de gros arbres et les d??racine pour passer ses nerfs.",
        1.4, 88.4, 211, 1250000),
       (236, "Debugant",
        "Debugant devient nerveux s'il ne s'entra??ne pas tous les jours. Lorsqu'un dresseur ??l??ve ce Pok??mon, il doit ??tablir et appliquer un programme d'entra??nement tr??s complet.",
        0.7, 21.0, 91, 1000000),
       (237, "Kapoera",
        "Kapoera tournoie ?? toute vitesse sur sa t??te, tout en donnant des coups de pied. Cette technique combine des attaques offensives et d??fensives. Ce Pok??mon se d??place plus vite sur la t??te qu'en marchant.",
        1.4, 48.0, 137, 1000000),
       (313, "Muciole",
        "?? la tomb??e de la nuit, la queue de Muciole ??met de la lumi??re. Il communique avec les autres en ajustant l'intensit?? et le clignotement de sa lumi??re. Ce Pok??mon est attir?? par le doux parfum de Lumivole.",
        0.7, 17.7, 146, 600000),
       (29, "Nidoran???",
        "Nidoran??? est couvert de pointes qui secr??tent un poison puissant. On pense que ce petit Pok??mon a d??velopp?? ces pointes pour se d??fendre. Lorsqu'il est en col??re, une horrible toxine sort de sa corne.",
        0.4, 7.0, 59, 1059860),
       (30, "Nidorina",
        "Lorsqu'un Nidorina est avec ses amis ou sa famille, il replie ses pointes pour ne pas blesser ses proches. Ce Pok??mon devient vite nerveux lorsqu'il est s??par?? de son groupe.",
        0.8, 20.0, 117, 1059860),
       (31, "Nidoqueen",
        "Le corps de Nidoqueen est prot??g?? par des ??cailles extr??mement dures. Il aime envoyer ses ennemis voler en leur fon??ant dessus. Ce Pok??mon utilise toute sa puissance lorsqu'il prot??ge ses petits.",
        1.3, 60.0, 194, 1059860),
       (115, "Kangourex",
        "Lorsqu'on rencontre un petit Kangourex qui joue tout seul, il ne faut jamais le d??ranger ou essayer de l'attraper. Les parents du b??b?? Pok??mon sont s??rement dans le coin et ils risquent d'entrer dans une col??re noire.",
        2.2, 80.0, 175, 1000000),
       (124, "Lippoutou",
        "Lippoutou marche en rythme, ondule de tout son corps et se d??hanche comme s'il dansait. Ses mouvements sont si communicatifs que les gens qui le voient sont soudain pris d'une terrible envie de bouger les hanches, sans r??fl??chir.",
        1.4, 40.6, 137, 1000000),
       (238, "Lippouti",
        "Lippouti court dans tous les sens et tombe assez souvent. Quand il en a l'occasion, il regarde son reflet dans l'eau pour v??rifier si son visage n'a pas ??t?? sali par ses chutes.",
        0.6, 6.0, 87, 1000000),
       (241, "??cr??meuh",
        "??cr??meuh produit plus de 20 l de lait par jour. Son lait sucr?? fait le bonheur des petits et des grands. Les gens qui ne boivent pas de lait en font du yaourt.",
        1.2, 75.5, 200, 1250000),
       (242, "Leuphorie",
        "Leuphorie ressent la tristesse gr??ce ?? son pelage duveteux. Lorsqu'il la remarque, ce Pok??mon se pr??cipite vers la personne triste pour partager avec elle un ??uf Chance, capable de faire na??tre un sourire sur tout visage.",
        1.5, 46.8, 608, 800000),
       (314, "Lumivole",
        "Lumivole peut attirer un essaim de Muciole gr??ce ?? son doux parfum. Une fois les Muciole rassembl??s, ce Pok??mon dirige cette nu??e lumineuse et lui fait dessiner des figures g??om??triques dans la nuit ??toil??e.",
        0.6, 17.7, 146, 1640000),
       (380, "Latias",
        "Latias est extr??mement sensible aux ??motions des gens. S'il ressent une hostilit??, ce Pok??mon ??bouriffe ses plumes et pousse un cri strident pour intimider son ennemi.",
        1.4, 40.0, 211, 1250000);

CALL pokemon_definir_localisation("Johto", 231, "Bulbizarre");
CALL pokemon_definir_localisation("Kalos", 80, "Bulbizarre");
CALL pokemon_definir_localisation("Johto", 232, "Herbizarre");
CALL pokemon_definir_localisation("Kalos", 81, "Herbizarre");
CALL pokemon_definir_localisation("Johto", 233, "Florizarre");
CALL pokemon_definir_localisation("Kalos", 82, "Florizarre");
CALL pokemon_definir_localisation("Johto", 234, "Salam??che");
CALL pokemon_definir_localisation("Kalos", 83, "Salam??che");
CALL pokemon_definir_localisation("Johto", 235, "Reptincel");
CALL pokemon_definir_localisation("Kalos", 84, "Reptincel");
CALL pokemon_definir_localisation("Kalos", 85, "Dracaufeu");
CALL pokemon_definir_localisation("Johto", 236, "Dracaufeu");
CALL pokemon_definir_localisation("Johto", 237, "Carapuce");
CALL pokemon_definir_localisation("Kalos", 86, "Carapuce");
CALL pokemon_definir_localisation("Kalos", 87, "Carabaffe");
CALL pokemon_definir_localisation("Johto", 238, "Carabaffe");
CALL pokemon_definir_localisation("Kalos", 88, "Tortank");
CALL pokemon_definir_localisation("Johto", 239, "Tortank");
CALL pokemon_definir_localisation("Johto", 24, "Chenipan");
CALL pokemon_definir_localisation("Kalos", 23, "Chenipan");
CALL pokemon_definir_localisation("Johto", 25, "Chrysacier");
CALL pokemon_definir_localisation("Kalos", 24, "Chrysacier");
CALL pokemon_definir_localisation("Johto", 26, "Papilusion");
CALL pokemon_definir_localisation("Kalos", 25, "Papilusion");
CALL pokemon_definir_localisation("Johto", 27, "Aspicot");
CALL pokemon_definir_localisation("Kalos", 26, "Aspicot");
CALL pokemon_definir_localisation("Johto", 28, "Coconfort");
CALL pokemon_definir_localisation("Kalos", 27, "Coconfort");
CALL pokemon_definir_localisation("Johto", 29, "Dardargnan");
CALL pokemon_definir_localisation("Kalos", 28, "Dardargnan");
CALL pokemon_definir_localisation("Johto", 10, "Roucool");
CALL pokemon_definir_localisation("Kalos", 17, "Roucool");
CALL pokemon_definir_localisation("Johto", 11, "Roucoups");
CALL pokemon_definir_localisation("Kalos", 18, "Roucoups");
CALL pokemon_definir_localisation("Johto", 12, "Roucarnage");
CALL pokemon_definir_localisation("Kalos", 19, "Roucarnage");
CALL pokemon_definir_localisation("Johto", 41, "M??lof??e");
CALL pokemon_definir_localisation("Sinnoh", 100, "M??lof??e");
CALL pokemon_definir_localisation("Unys", 89, "M??lof??e");
CALL pokemon_definir_localisation("Johto", 42, "M??lodelfe");
CALL pokemon_definir_localisation("Sinnoh", 101, "M??lodelfe");
CALL pokemon_definir_localisation("Unys", 90, "M??lodelfe");
CALL pokemon_definir_localisation("Johto", 127, "Goupix");
CALL pokemon_definir_localisation("Hoenn", 153, "Goupix");
CALL pokemon_definir_localisation("Unys", 248, "Goupix");
CALL pokemon_definir_localisation("Johto", 128, "Feunard");
CALL pokemon_definir_localisation("Hoenn", 154, "Feunard");
CALL pokemon_definir_localisation("Unys", 249, "Feunard");
CALL pokemon_definir_localisation("Johto", 44, "Rondoudou");
CALL pokemon_definir_localisation("Kalos", 120, "Rondoudou");
CALL pokemon_definir_localisation("Hoenn", 138, "Rondoudou");
CALL pokemon_definir_localisation("Unys", 282, "Grodoudou");
CALL pokemon_definir_localisation("Johto", 45, "Grodoudou");
CALL pokemon_definir_localisation("Kalos", 121, "Grodoudou");
CALL pokemon_definir_localisation("Hoenn", 139, "Grodoudou");
CALL pokemon_definir_localisation("Unys", 283, "Grodoudou");
CALL pokemon_definir_localisation("Johto", 40, "M??lo");
CALL pokemon_definir_localisation("Sinnoh", 99, "M??lo");
CALL pokemon_definir_localisation("Unys", 88, "M??lo");
CALL pokemon_definir_localisation("Unys", 282, "Toudoudou");
CALL pokemon_definir_localisation("Johto", 45, "Toudoudou");
CALL pokemon_definir_localisation("Kalos", 121, "Toudoudou");
CALL pokemon_definir_localisation("Hoenn", 139, "Toudoudou");
CALL pokemon_definir_localisation("Unys", 283, "Toudoudou");
CALL pokemon_definir_localisation("Johto", 95, "Nidoran???");
CALL pokemon_definir_localisation("Kalos", 104, "Nidoran???");
CALL pokemon_definir_localisation("Johto", 96, "Nidorino");
CALL pokemon_definir_localisation("Kalos", 105, "Nidorino");
CALL pokemon_definir_localisation("Johto", 97, "Nidoking");
CALL pokemon_definir_localisation("Kalos", 106, "Nidoking");
CALL pokemon_definir_localisation("Johto", 146, "Kicklee");
CALL pokemon_definir_localisation("Johto", 147, "Tygnon");
CALL pokemon_definir_localisation("Johto", 150, "Tauros");
CALL pokemon_definir_localisation("Kalos", 125, "Tauros");
CALL pokemon_definir_localisation("Johto", 145, "Debugant");
CALL pokemon_definir_localisation("Johto", 148, "Kapoera");
CALL pokemon_definir_localisation("Kalos", 133, "Muciole");
CALL pokemon_definir_localisation("Hoenn", 86, "Muciole");
CALL pokemon_definir_localisation("Johto", 98, "Nidoran???");
CALL pokemon_definir_localisation("Kalos", 107, "Nidoran???");
CALL pokemon_definir_localisation("Johto", 99, "Nidorina");
CALL pokemon_definir_localisation("Kalos", 108, "Nidorina");
CALL pokemon_definir_localisation("Johto", 100, "Nidoqueen");
CALL pokemon_definir_localisation("Kalos", 109, "Nidoqueen");
CALL pokemon_definir_localisation("Johto", 210, "Kangourex");
CALL pokemon_definir_localisation("Kalos", 62, "Kangourex");
CALL pokemon_definir_localisation("Johto", 155, "Lippoutou");
CALL pokemon_definir_localisation("Kalos", 84, "Lippoutou");
CALL pokemon_definir_localisation("Johto", 154, "Lippouti");
CALL pokemon_definir_localisation("Kalos", 83, "Lippouti");
CALL pokemon_definir_localisation("Johto", 151, "??cr??meuh");
CALL pokemon_definir_localisation("Kalos", 126, "??cr??meuh");
CALL pokemon_definir_localisation("Johto", 223, "Leuphorie");
CALL pokemon_definir_localisation("Sinnoh", 98, "Leuphorie");
CALL pokemon_definir_localisation("Hoenn", 87, "Lumivole");
CALL pokemon_definir_localisation("Kalos", 134, "Lumivole");
CALL pokemon_definir_localisation("Hoenn", 196, "Latias");

CALL pokemon_definir_categorisation("Bulbizarre", "Graine");
CALL pokemon_definir_categorisation("Herbizarre", "Graine");
CALL pokemon_definir_categorisation("Florizarre", "Graine");
CALL pokemon_definir_categorisation("M??ga-Florizarre", "Graine");
CALL pokemon_definir_categorisation("Salam??che", "L??zard");
CALL pokemon_definir_categorisation("Reptincel", "Flamme");
CALL pokemon_definir_categorisation("Dracaufeu", "Flamme");
CALL pokemon_definir_categorisation("Salam??che", "Flamme");
CALL pokemon_definir_categorisation("Carapuce", "Minitortue");
CALL pokemon_definir_categorisation("Carabaffe", "Tortue");
CALL pokemon_definir_categorisation("Tortank", "Carapace");
CALL pokemon_definir_categorisation("Chenipan", "Ver");
CALL pokemon_definir_categorisation("Chrysacier", "Cocon");
CALL pokemon_definir_categorisation("Papilusion", "Papillon");
CALL pokemon_definir_categorisation("Aspicot", "Insectopic");
CALL pokemon_definir_categorisation("Coconfort", "Cocon");
CALL pokemon_definir_categorisation("Dardargnan", "Gu??poison");
CALL pokemon_definir_categorisation("Roucool", "Minoiseau");
CALL pokemon_definir_categorisation("Roucoups", "Oiseau");
CALL pokemon_definir_categorisation("Roucarnage", "Oiseau");
CALL pokemon_definir_categorisation("M??lof??e", "F??e");
CALL pokemon_definir_categorisation("M??lodelfe", "F??e");
CALL pokemon_definir_categorisation("Goupix", "Renard");
CALL pokemon_definir_categorisation("Goupix d'Alola", "Renard");
CALL pokemon_definir_categorisation("Feunard", "Renard");
CALL pokemon_definir_categorisation("Feunard d'Alola", "Renard");
CALL pokemon_definir_categorisation("Rondoudou", "Bouboule");
CALL pokemon_definir_categorisation("Grodoudou", "Bouboule");
CALL pokemon_definir_categorisation("M??lo", "??toile");
CALL pokemon_definir_categorisation("Toudoudou", "Bouboule");
CALL pokemon_definir_categorisation("Nidoran???", "V??n??pic");
CALL pokemon_definir_categorisation("Nidorino", "V??n??pic");
CALL pokemon_definir_categorisation("Nidoking", "Perceur");
CALL pokemon_definir_categorisation("Kicklee", "Latteur");
CALL pokemon_definir_categorisation("Tygnon", "Puncheur");
CALL pokemon_definir_categorisation("Tauros", "Buffle");
CALL pokemon_definir_categorisation("Debugant", "Debugant");
CALL pokemon_definir_categorisation("Kapoera", "Poirier");
CALL pokemon_definir_categorisation("Muciole", "Luciole");
CALL pokemon_definir_categorisation("Nidoran???", "V??n??pic");
CALL pokemon_definir_categorisation("Nidorina", "V??n??pic");
CALL pokemon_definir_categorisation("Nidoqueen", "Perceur");
CALL pokemon_definir_categorisation("Kangourex", "Maternel");
CALL pokemon_definir_categorisation("Lippoutou", "Humano??de");
CALL pokemon_definir_categorisation("Lippouti", "Bisou");
CALL pokemon_definir_categorisation("??cr??meuh", "Vachalait");
CALL pokemon_definir_categorisation("Leuphorie", "Bonheur");
CALL pokemon_definir_categorisation("Lumivole", "Luciole");
CALL pokemon_definir_categorisation("Latias", "??on");

CALL pokemon_definir_force("Bulbizarre", "Eau");
CALL pokemon_definir_force("Bulbizarre", "Roche");
CALL pokemon_definir_force("Bulbizarre", "Sol");
CALL pokemon_definir_force("Herbizarre", "Eau");
CALL pokemon_definir_force("Herbizarre", "Roche");
CALL pokemon_definir_force("Herbizarre", "Sol");
CALL pokemon_definir_force("Florizarre", "Eau");
CALL pokemon_definir_force("Florizarre", "Roche");
CALL pokemon_definir_force("Florizarre", "Sol");
CALL pokemon_definir_force("M??ga-Florizarre", "Eau");
CALL pokemon_definir_force("M??ga-Florizarre", "Roche");
CALL pokemon_definir_force("M??ga-Florizarre", "Sol");
CALL pokemon_definir_force("Salam??che", "Acier");
CALL pokemon_definir_force("Salam??che", "Glace");
CALL pokemon_definir_force("Salam??che", "Insecte");
CALL pokemon_definir_force("Salam??che", "Plante");
CALL pokemon_definir_force("Reptincel", "Acier");
CALL pokemon_definir_force("Reptincel", "Glace");
CALL pokemon_definir_force("Reptincel", "Insecte");
CALL pokemon_definir_force("Reptincel", "Plante");
CALL pokemon_definir_force("Dracaufeu", "Acier");
CALL pokemon_definir_force("Dracaufeu", "Combat");
CALL pokemon_definir_force("Dracaufeu", "Glace");
CALL pokemon_definir_force("Dracaufeu", "Insecte");
CALL pokemon_definir_force("Dracaufeu", "Plante");
CALL pokemon_definir_force("Carapuce", "Feu");
CALL pokemon_definir_force("Carapuce", "Sol");
CALL pokemon_definir_force("Carapuce", "Roche");
CALL pokemon_definir_force("Carabaffe", "Feu");
CALL pokemon_definir_force("Carabaffe", "Sol");
CALL pokemon_definir_force("Carabaffe", "Roche");
CALL pokemon_definir_force("Tortank", "Feu");
CALL pokemon_definir_force("Tortank", "Sol");
CALL pokemon_definir_force("Tortank", "Roche");
CALL pokemon_definir_force("Chenipan", "Combat");
CALL pokemon_definir_force("Chenipan", "Plante");
CALL pokemon_definir_force("Chenipan", "Sol");
CALL pokemon_definir_force("Chrysacier", "Combat");
CALL pokemon_definir_force("Chrysacier", "Plante");
CALL pokemon_definir_force("Papilusion", "Combat");
CALL pokemon_definir_force("Papilusion", "Plante");
CALL pokemon_definir_force("Aspicot", "Combat");
CALL pokemon_definir_force("Aspicot", "F??e");
CALL pokemon_definir_force("Aspicot", "Plante");
CALL pokemon_definir_force("Coconfort", "Psy");
CALL pokemon_definir_force("Coconfort", "Plante");
CALL pokemon_definir_force("Coconfort", "T??n??bres");
CALL pokemon_definir_force("Dardargnan", "Combat");
CALL pokemon_definir_force("Dardargnan", "F??e");
CALL pokemon_definir_force("Dardargnan", "Plante");
CALL pokemon_definir_force("Roucool", "Insecte");
CALL pokemon_definir_force("Roucool", "Plante");
CALL pokemon_definir_force("Roucoups", "Insecte");
CALL pokemon_definir_force("Roucoups", "Plante");
CALL pokemon_definir_force("Roucarnage", "Insecte");
CALL pokemon_definir_force("Roucarnage", "Plante");
CALL pokemon_definir_force("M??lof??e", "Combat");
CALL pokemon_definir_force("M??lof??e", "Insecte");
CALL pokemon_definir_force("M??lof??e", "T??n??bres");
CALL pokemon_definir_force("M??lodelfe", "Combat");
CALL pokemon_definir_force("M??lodelfe", "Insecte");
CALL pokemon_definir_force("M??lodelfe", "T??n??bres");
CALL pokemon_definir_force("Goupix", "Acier");
CALL pokemon_definir_force("Goupix", "F??e");
CALL pokemon_definir_force("Goupix", "Glace");
CALL pokemon_definir_force("Goupix", "Insecte");
CALL pokemon_definir_force("Goupix", "Plante");
CALL pokemon_definir_force("Goupix d'Alola", "Glace");
CALL pokemon_definir_force("Feunard d'Alola", "Plante");
CALL pokemon_definir_force("Feunard d'Alola", "Sol");
CALL pokemon_definir_force("Feunard d'Alola", "Vol");
CALL pokemon_definir_force("Feunard", "Acier");
CALL pokemon_definir_force("Feunard", "F??e");
CALL pokemon_definir_force("Feunard", "Glace");
CALL pokemon_definir_force("Feunard", "Insecte");
CALL pokemon_definir_force("Feunard", "Plante");
CALL pokemon_definir_force("Feunard d'Alola", "Combat");
CALL pokemon_definir_force("Feunard d'Alola", "Dragon");
CALL pokemon_definir_force("Feunard d'Alola", "T??n??bres");
CALL pokemon_definir_force("Rondoudou", "Insecte");
CALL pokemon_definir_force("Rondoudou", "T??n??bres");
CALL pokemon_definir_force("Grodoudou", "Insecte");
CALL pokemon_definir_force("Grodoudou", "T??n??bres");
CALL pokemon_definir_force("M??lo", "Combat");
CALL pokemon_definir_force("M??lo", "Insecte");
CALL pokemon_definir_force("M??lo", "T??n??bres");
CALL pokemon_definir_force("Toudoudou", "Insecte");
CALL pokemon_definir_force("Toudoudou", "T??n??bres");
CALL pokemon_definir_force("Nidoran???", "Combat");
CALL pokemon_definir_force("Nidoran???", "F??e");
CALL pokemon_definir_force("Nidoran???", "Insecte");
CALL pokemon_definir_force("Nidoran???", "Plante");
CALL pokemon_definir_force("Nidorino", "Combat");
CALL pokemon_definir_force("Nidorino", "F??e");
CALL pokemon_definir_force("Nidorino", "Insecte");
CALL pokemon_definir_force("Nidorino", "Plante");
CALL pokemon_definir_force("Nidoking", "Combat");
CALL pokemon_definir_force("Nidoking", "F??e");
CALL pokemon_definir_force("Nidoking", "Insecte");
CALL pokemon_definir_force("Nidoking", "Plante");
CALL pokemon_definir_force("Nidoking", "Roche");
CALL pokemon_definir_force("Kicklee", "Insecte");
CALL pokemon_definir_force("Kicklee", "Roche");
CALL pokemon_definir_force("Kicklee", "T??n??bres");
CALL pokemon_definir_force("Tygnon", "Insecte");
CALL pokemon_definir_force("Tygnon", "Roche");
CALL pokemon_definir_force("Tygnon", "T??n??bres");
CALL pokemon_definir_force("Debugant", "Insecte");
CALL pokemon_definir_force("Debugant", "Roche");
CALL pokemon_definir_force("Debugant", "T??n??bres");
CALL pokemon_definir_force("Kapoera", "Insecte");
CALL pokemon_definir_force("Kapoera", "Roche");
CALL pokemon_definir_force("Muciole", "Combat");
CALL pokemon_definir_force("Muciole", "Plante");
CALL pokemon_definir_force("Muciole", "Sol");
CALL pokemon_definir_force("Nidoran???", "Combat");
CALL pokemon_definir_force("Nidoran???", "F??e");
CALL pokemon_definir_force("Nidoran???", "Insecte");
CALL pokemon_definir_force("Nidoran???", "Plante");
CALL pokemon_definir_force("Nidorina", "Combat");
CALL pokemon_definir_force("Nidorina", "F??e");
CALL pokemon_definir_force("Nidorina", "Insecte");
CALL pokemon_definir_force("Nidorina", "Plante");
CALL pokemon_definir_force("Nidoqueen", "Combat");
CALL pokemon_definir_force("Nidoqueen", "F??e");
CALL pokemon_definir_force("Nidoqueen", "Insecte");
CALL pokemon_definir_force("Nidoqueen", "Plante");
CALL pokemon_definir_force("Nidoqueen", "Roche");
CALL pokemon_definir_force("Lippoutou", "Combat");
CALL pokemon_definir_force("Lippoutou", "Poison");
CALL pokemon_definir_force("Lippouti", "Combat");
CALL pokemon_definir_force("Lippouti", "Poison");
CALL pokemon_definir_force("Leuphorie", "Spectre");
CALL pokemon_definir_force("Lumivole", "Combat");
CALL pokemon_definir_force("Lumivole", "Plante");
CALL pokemon_definir_force("Lumivole", "Sol");
CALL pokemon_definir_force("Latias", "Combat");
CALL pokemon_definir_force("Latias", "Poison");

CALL pokemon_definir_faiblesse("Bulbizarre", "Feu");
CALL pokemon_definir_faiblesse("Bulbizarre", "Psy");
CALL pokemon_definir_faiblesse("Bulbizarre", "Vol");
CALL pokemon_definir_faiblesse("Bulbizarre", "Glace");
CALL pokemon_definir_faiblesse("Herbizarre", "Feu");
CALL pokemon_definir_faiblesse("Herbizarre", "Psy");
CALL pokemon_definir_faiblesse("Herbizarre", "Vol");
CALL pokemon_definir_faiblesse("Herbizarre", "Glace");
CALL pokemon_definir_faiblesse("Florizarre", "Feu");
CALL pokemon_definir_faiblesse("Florizarre", "Psy");
CALL pokemon_definir_faiblesse("Florizarre", "Vol");
CALL pokemon_definir_faiblesse("Florizarre", "Glace");
CALL pokemon_definir_faiblesse("M??ga-Florizarre", "Feu");
CALL pokemon_definir_faiblesse("M??ga-Florizarre", "Psy");
CALL pokemon_definir_faiblesse("M??ga-Florizarre", "Vol");
CALL pokemon_definir_faiblesse("M??ga-Florizarre", "Glace");
CALL pokemon_definir_faiblesse("Salam??che", "Eau");
CALL pokemon_definir_faiblesse("Salam??che", "Sol");
CALL pokemon_definir_faiblesse("Salam??che", "Roche");
CALL pokemon_definir_faiblesse("Reptincel", "Eau");
CALL pokemon_definir_faiblesse("Reptincel", "Sol");
CALL pokemon_definir_faiblesse("Reptincel", "Roche");
CALL pokemon_definir_faiblesse("Dracaufeu", "Eau");
CALL pokemon_definir_faiblesse("Dracaufeu", "??lectrik");
CALL pokemon_definir_faiblesse("Dracaufeu", "Roche");
CALL pokemon_definir_faiblesse("Carapuce", "Plante");
CALL pokemon_definir_faiblesse("Carapuce", "??lectrik");
CALL pokemon_definir_faiblesse("Carabaffe", "Plante");
CALL pokemon_definir_faiblesse("Carabaffe", "??lectrik");
CALL pokemon_definir_faiblesse("Tortank", "Plante");
CALL pokemon_definir_faiblesse("Tortank", "??lectrik");
CALL pokemon_definir_faiblesse("Chenipan", "Feu");
CALL pokemon_definir_faiblesse("Chenipan", "Vol");
CALL pokemon_definir_faiblesse("Chenipan", "Roche");
CALL pokemon_definir_faiblesse("Chrysacier", "Feu");
CALL pokemon_definir_faiblesse("Chrysacier", "Vol");
CALL pokemon_definir_faiblesse("Chrysacier", "Roche");
CALL pokemon_definir_faiblesse("Papilusion", "Feu");
CALL pokemon_definir_faiblesse("Papilusion", "??lectrik");
CALL pokemon_definir_faiblesse("Papilusion", "Glace");
CALL pokemon_definir_faiblesse("Papilusion", "Roche");
CALL pokemon_definir_faiblesse("Aspicot", "Feu");
CALL pokemon_definir_faiblesse("Aspicot", "Psy");
CALL pokemon_definir_faiblesse("Aspicot", "Vol");
CALL pokemon_definir_faiblesse("Aspicot", "Roche");
CALL pokemon_definir_faiblesse("Coconfort", "Feu");
CALL pokemon_definir_faiblesse("Coconfort", "Vol");
CALL pokemon_definir_faiblesse("Coconfort", "Roche");
CALL pokemon_definir_faiblesse("Dardargnan", "Feu");
CALL pokemon_definir_faiblesse("Dardargnan", "Psy");
CALL pokemon_definir_faiblesse("Dardargnan", "Vol");
CALL pokemon_definir_faiblesse("Dardargnan", "Roche");
CALL pokemon_definir_faiblesse("Roucool", "??lectrik");
CALL pokemon_definir_faiblesse("Roucool", "Glace");
CALL pokemon_definir_faiblesse("Roucool", "Roche");
CALL pokemon_definir_faiblesse("Roucoups", "??lectrik");
CALL pokemon_definir_faiblesse("Roucoups", "Glace");
CALL pokemon_definir_faiblesse("Roucoups", "Roche");
CALL pokemon_definir_faiblesse("Roucarnage", "??lectrik");
CALL pokemon_definir_faiblesse("Roucarnage", "Glace");
CALL pokemon_definir_faiblesse("M??lof??e", "Acier");
CALL pokemon_definir_faiblesse("M??lof??e", "poison");
CALL pokemon_definir_faiblesse("M??lodelfe", "Acier");
CALL pokemon_definir_faiblesse("M??lodelfe", "Poison");
CALL pokemon_definir_faiblesse("Goupix", "Eau");
CALL pokemon_definir_faiblesse("Goupix", "Sol");
CALL pokemon_definir_faiblesse("Goupix", "Roche");
CALL pokemon_definir_faiblesse("Goupix d'Alola", "Eau");
CALL pokemon_definir_faiblesse("Goupix d'Alola", "Sol");
CALL pokemon_definir_faiblesse("Goupix d'Alola", "Roche");
CALL pokemon_definir_faiblesse("Feunard d'Alola", "Acier");
CALL pokemon_definir_faiblesse("Feunard d'Alola", "Roche");
CALL pokemon_definir_faiblesse("Feunard", "Eau");
CALL pokemon_definir_faiblesse("Feunard", "Sol");
CALL pokemon_definir_faiblesse("Feunard", "Roche");
CALL pokemon_definir_faiblesse("Rondoudou", "Acier");
CALL pokemon_definir_faiblesse("Rondoudou", "Poison");
CALL pokemon_definir_faiblesse("Grodoudou", "Acier");
CALL pokemon_definir_faiblesse("Grodoudou", "Poison");
CALL pokemon_definir_faiblesse("M??lo", "Acier");
CALL pokemon_definir_faiblesse("M??lo", "Poison");
CALL pokemon_definir_faiblesse("Toudoudou", "Acier");
CALL pokemon_definir_faiblesse("Toudoudou", "Poison");
CALL pokemon_definir_faiblesse("Nidoran???", "Psy");
CALL pokemon_definir_faiblesse("Nidoran???", "Sol");
CALL pokemon_definir_faiblesse("Nidorino", "Psy");
CALL pokemon_definir_faiblesse("Nidorino", "Sol");
CALL pokemon_definir_faiblesse("Nidoking", "Eau");
CALL pokemon_definir_faiblesse("Nidoking", "Glace");
CALL pokemon_definir_faiblesse("Nidoking", "Psy");
CALL pokemon_definir_faiblesse("Kicklee", "F??e");
CALL pokemon_definir_faiblesse("Kicklee", "Psy");
CALL pokemon_definir_faiblesse("Kicklee", "Vol");
CALL pokemon_definir_faiblesse("Tygnon", "F??e");
CALL pokemon_definir_faiblesse("Tygnon", "Psy");
CALL pokemon_definir_faiblesse("Tygnon", "Vol");
CALL pokemon_definir_faiblesse("Tauros", "Combat");
CALL pokemon_definir_faiblesse("Debugant", "F??e");
CALL pokemon_definir_faiblesse("Debugant", "psy");
CALL pokemon_definir_faiblesse("Debugant", "Vol");
CALL pokemon_definir_faiblesse("Kapoera", "F??e");
CALL pokemon_definir_faiblesse("Kapoera", "Psy");
CALL pokemon_definir_faiblesse("Kapoera", "Vol");
CALL pokemon_definir_faiblesse("Muciole", "Feu");
CALL pokemon_definir_faiblesse("Muciole", "Roche");
CALL pokemon_definir_faiblesse("Muciole", "Vol");
CALL pokemon_definir_faiblesse("Nidoran???", "Psy");
CALL pokemon_definir_faiblesse("Nidoran???", "Sol");
CALL pokemon_definir_faiblesse("Nidorina", "Psy");
CALL pokemon_definir_faiblesse("Nidorina", "Sol");
CALL pokemon_definir_faiblesse("Nidoqueen", "Eau");
CALL pokemon_definir_faiblesse("Nidoqueen", "Glace");
CALL pokemon_definir_faiblesse("Nidoqueen", "Psy");
CALL pokemon_definir_faiblesse("Kangourex", "Combat");
CALL pokemon_definir_faiblesse("Lippoutou", "Acier");
CALL pokemon_definir_faiblesse("Lippoutou", "Feu");
CALL pokemon_definir_faiblesse("Lippoutou", "Insecte");
CALL pokemon_definir_faiblesse("Lippoutou", "Roche");
CALL pokemon_definir_faiblesse("Lippoutou", "Spectre");
CALL pokemon_definir_faiblesse("Lippouti", "Acier");
CALL pokemon_definir_faiblesse("Lippouti", "Feu");
CALL pokemon_definir_faiblesse("Lippouti", "Insecte");
CALL pokemon_definir_faiblesse("Lippouti", "T??n??bres");
CALL pokemon_definir_faiblesse("Lippouti", "Spectre");
CALL pokemon_definir_faiblesse("??cr??meuh", "Combat");
CALL pokemon_definir_faiblesse("Leuphorie", "Combat");
CALL pokemon_definir_faiblesse("Lumivole", "Feu");
CALL pokemon_definir_faiblesse("Lumivole", "Vol");
CALL pokemon_definir_faiblesse("Lumivole", "Roche");
CALL pokemon_definir_faiblesse("Latias", "F??e");
CALL pokemon_definir_faiblesse("Latias", "Glace");
CALL pokemon_definir_faiblesse("Latias", "Insecte");
CALL pokemon_definir_faiblesse("Latias", "Spectre");
CALL pokemon_definir_faiblesse("Latias", "T??n??bres");

CALL pokemon_definir_type("Bulbizarre", "Plante");
CALL pokemon_definir_type("Bulbizarre", "Poison");
CALL pokemon_definir_type("Herbizarre", "Plante");
CALL pokemon_definir_type("Herbizarre", "Poison");

CALL pokemon_definir_type("Florizarre", "Plante");
CALL pokemon_definir_type("Florizarre", "Poison");

CALL pokemon_definir_type("M??ga-Florizarre", "Plante");
CALL pokemon_definir_type("M??ga-Florizarre", "Poison");

CALL pokemon_definir_type("Salam??che", "Feu");
CALL pokemon_definir_type("Reptincel", "Feu");
CALL pokemon_definir_type("Dracaufeu", "Feu");
CALL pokemon_definir_type("Dracaufeu", "Dragon");
CALL pokemon_definir_type("Dracaufeu", "Vol");
CALL pokemon_definir_type("Carapuce", "Eau");
CALL pokemon_definir_type("Carabaffe", "Eau");
CALL pokemon_definir_type("Tortank", "Eau");
CALL pokemon_definir_type("Chenipan", "Insecte");
CALL pokemon_definir_type("Chrysacier", "Insecte");
CALL pokemon_definir_type("Papilusion", "Insecte");
CALL pokemon_definir_type("Papilusion", "Vol");
CALL pokemon_definir_type("Aspicot", "Insecte");
CALL pokemon_definir_type("Aspicot", "Poison");
CALL pokemon_definir_type("Coconfort", "Insecte");
CALL pokemon_definir_type("Coconfort", "Poison");
CALL pokemon_definir_type("Dardargnan", "Insecte");
CALL pokemon_definir_type("Dardargnan", "Poison");
CALL pokemon_definir_type("Roucool", "Normal");
CALL pokemon_definir_type("Roucool", "Vol");
CALL pokemon_definir_type("Roucoups", "Normal");
CALL pokemon_definir_type("Roucoups", "Vol");
CALL pokemon_definir_type("Roucarnage", "Vol");
CALL pokemon_definir_type("Roucarnage", "Normal");
CALL pokemon_definir_type("M??lof??e", "F??e");
CALL pokemon_definir_type("M??lodelfe", "F??e");
CALL pokemon_definir_type("Goupix", "Feu");
CALL pokemon_definir_type("Goupix d'Alola", "Feu");
CALL pokemon_definir_type("Feunard", "Feu");
CALL pokemon_definir_type("Feunard d'Alola", "Feu");
CALL pokemon_definir_type("Rondoudou", "Normal");
CALL pokemon_definir_type("Rondoudou", "F??e");
CALL pokemon_definir_type("Grodoudou", "Normal");
CALL pokemon_definir_type("Grodoudou", "F??e");
CALL pokemon_definir_type("M??lo", "F??e");
CALL pokemon_definir_type("Toudoudou", "F??e");
CALL pokemon_definir_type("Toudoudou", "Normal");
CALL pokemon_definir_type("Nidoran???", "Poison");
CALL pokemon_definir_type("Nidorino", "Poison");
CALL pokemon_definir_type("Nidoking", "Poison");
CALL pokemon_definir_type("Nidoking", "Sol");
CALL pokemon_definir_type("Kicklee", "Combat");
CALL pokemon_definir_type("Tygnon", "Combat");
CALL pokemon_definir_type("Tauros", "Normal");
CALL pokemon_definir_type("Debugant", "Combat");
CALL pokemon_definir_type("Kapoera", "Combat");
CALL pokemon_definir_type("Muciole", "Insecte");
CALL pokemon_definir_type("Nidoran???", "Poison");
CALL pokemon_definir_type("Nidorina", "Poison");
CALL pokemon_definir_type("Nidoqueen", "Poison");
CALL pokemon_definir_type("Nidoqueen", "Sol");
CALL pokemon_definir_type("Kangourex", "Normal");
CALL pokemon_definir_type("Lippoutou", "Glace");
CALL pokemon_definir_type("Lippoutou", "Psy");
CALL pokemon_definir_type("Lippouti", "Glace");
CALL pokemon_definir_type("Lippouti", "Psy");
CALL pokemon_definir_type("??cr??meuh", "Normal");
CALL pokemon_definir_type("Leuphorie", "Normal");
CALL pokemon_definir_type("Lumivole", "Insecte");
CALL pokemon_definir_type("Latias", "Dragon");
CALL pokemon_definir_type("Latias", "Psy");

CALL pokemon_definir_attaque("Bulbizarre", "Charge");
CALL pokemon_definir_attaque("Bulbizarre", "Rugissement");
CALL pokemon_definir_attaque("Bulbizarre", "Fouet Lianes");
CALL pokemon_definir_attaque("Bulbizarre", "Croissance");
CALL pokemon_definir_attaque("Bulbizarre", "Vampigraine");
CALL pokemon_definir_attaque("Bulbizarre", "Tranch'Herbe");
CALL pokemon_definir_attaque("Bulbizarre", "Poudre Dodo");
CALL pokemon_definir_attaque("Bulbizarre", "Poudre Toxik");
CALL pokemon_definir_attaque("Bulbizarre", "Canon Graine");
CALL pokemon_definir_attaque("Bulbizarre", "B??lier");
CALL pokemon_definir_attaque("Bulbizarre", "Doux Parfum");
CALL pokemon_definir_attaque("Bulbizarre", "Synth??se");
CALL pokemon_definir_attaque("Bulbizarre", "Soucigraine");
CALL pokemon_definir_attaque("Bulbizarre", "Damocl??s");
CALL pokemon_definir_attaque("Bulbizarre", "Lance-Soleil");
CALL pokemon_definir_attaque("Herbizarre", "Charge");
CALL pokemon_definir_attaque("Herbizarre", "Rugissement");
CALL pokemon_definir_attaque("Herbizarre", "Fouet Lianes");
CALL pokemon_definir_attaque("Herbizarre", "Croissance");
CALL pokemon_definir_attaque("Herbizarre", "Vampigraine");
CALL pokemon_definir_attaque("Herbizarre", "Tranch'Herbe");
CALL pokemon_definir_attaque("Herbizarre", "Poudre Dodo");
CALL pokemon_definir_attaque("Herbizarre", "Poudre Toxik");
CALL pokemon_definir_attaque("Herbizarre", "Canon Graine");
CALL pokemon_definir_attaque("Herbizarre", "B??lier");
CALL pokemon_definir_attaque("Herbizarre", "Doux Parfum");
CALL pokemon_definir_attaque("Herbizarre", "Synth??se");
CALL pokemon_definir_attaque("Herbizarre", "Soucigraine");
CALL pokemon_definir_attaque("Herbizarre", "Damocl??s");
CALL pokemon_definir_attaque("Herbizarre", "Lance-Soleil");
CALL pokemon_definir_attaque("Florizarre", "Charge");
CALL pokemon_definir_attaque("Florizarre", "Rugissement");
CALL pokemon_definir_attaque("Florizarre", "Fouet Lianes");
CALL pokemon_definir_attaque("Florizarre", "Croissance");
CALL pokemon_definir_attaque("Florizarre", "Vampigraine");
CALL pokemon_definir_attaque("Florizarre", "Tranch'Herbe");
CALL pokemon_definir_attaque("Florizarre", "Poudre Dodo");
CALL pokemon_definir_attaque("Florizarre", "Poudre Toxik");
CALL pokemon_definir_attaque("Florizarre", "Canon Graine");
CALL pokemon_definir_attaque("Florizarre", "B??lier");
CALL pokemon_definir_attaque("Florizarre", "Doux Parfum");
CALL pokemon_definir_attaque("Florizarre", "Synth??se");
CALL pokemon_definir_attaque("Florizarre", "Soucigraine");
CALL pokemon_definir_attaque("Florizarre", "Damocl??s");
CALL pokemon_definir_attaque("Florizarre", "Lance-Soleil");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Charge");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Rugissement");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Fouet Lianes");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Croissance");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Vampigraine");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Tranch'Herbe");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Poudre Dodo");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Poudre Toxik");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Canon Graine");
CALL pokemon_definir_attaque("M??ga-Florizarre", "B??lier");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Doux Parfum");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Synth??se");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Soucigraine");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Damocl??s");
CALL pokemon_definir_attaque("M??ga-Florizarre", "Lance-Soleil");
CALL pokemon_definir_attaque("Salam??che", "Griffe");
CALL pokemon_definir_attaque("Salam??che", "Rugissement");
CALL pokemon_definir_attaque("Salam??che", "Flamm??che");
CALL pokemon_definir_attaque("Salam??che", "Brouillard");
CALL pokemon_definir_attaque("Salam??che", "Dracosouffle");
CALL pokemon_definir_attaque("Salam??che", "Crocs Feu");
CALL pokemon_definir_attaque("Salam??che", "Tranche");
CALL pokemon_definir_attaque("Salam??che", "Lance-Flammes");
CALL pokemon_definir_attaque("Salam??che", "Grimace");
CALL pokemon_definir_attaque("Salam??che", "Danse Flamme");
CALL pokemon_definir_attaque("Salam??che", "Feu d'Enfer");
CALL pokemon_definir_attaque("Salam??che", "Boutefeu");
CALL pokemon_definir_attaque("Reptincel", "Griffe");
CALL pokemon_definir_attaque("Reptincel", "Rugissement");
CALL pokemon_definir_attaque("Reptincel", "Flamm??che");
CALL pokemon_definir_attaque("Reptincel", "Brouillard");
CALL pokemon_definir_attaque("Reptincel", "Dracosouffle");
CALL pokemon_definir_attaque("Reptincel", "Crocs Feu");
CALL pokemon_definir_attaque("Reptincel", "Tranche");
CALL pokemon_definir_attaque("Reptincel", "Lance-Flammes");
CALL pokemon_definir_attaque("Reptincel", "Grimace");
CALL pokemon_definir_attaque("Reptincel", "Danse Flamme");
CALL pokemon_definir_attaque("Reptincel", "Feu d'Enfer");
CALL pokemon_definir_attaque("Reptincel", "Boutefeu");
CALL pokemon_definir_attaque("Dracaufeu", "Griffe");
CALL pokemon_definir_attaque("Dracaufeu", "Rugissement");
CALL pokemon_definir_attaque("Dracaufeu", "Flamm??che");
CALL pokemon_definir_attaque("Dracaufeu", "Brouillard");
CALL pokemon_definir_attaque("Dracaufeu", "Dracosouffle");
CALL pokemon_definir_attaque("Dracaufeu", "Crocs Feu");
CALL pokemon_definir_attaque("Dracaufeu", "Tranche");
CALL pokemon_definir_attaque("Dracaufeu", "Lance-Flammes");
CALL pokemon_definir_attaque("Dracaufeu", "Grimace");
CALL pokemon_definir_attaque("Dracaufeu", "Danse Flamme");
CALL pokemon_definir_attaque("Dracaufeu", "Feu d'Enfer");
CALL pokemon_definir_attaque("Dracaufeu", "Boutefeu");
CALL pokemon_definir_attaque("Carapuce", "Charge");
CALL pokemon_definir_attaque("Carapuce", "Mimi-Queue");
CALL pokemon_definir_attaque("Carapuce", "Pistolet ?? O");
CALL pokemon_definir_attaque("Carapuce", "Repli");
CALL pokemon_definir_attaque("Carapuce", "Tour Rapide");
CALL pokemon_definir_attaque("Carapuce", "Morsure");
CALL pokemon_definir_attaque("Carapuce", "Vibraqua");
CALL pokemon_definir_attaque("Carapuce", "Abri");
CALL pokemon_definir_attaque("Carapuce", "Hydroqueue");
CALL pokemon_definir_attaque("Carapuce", "Exuviation");
CALL pokemon_definir_attaque("Carapuce", "Hydrocanon");
CALL pokemon_definir_attaque("Carabaffe", "Charge");
CALL pokemon_definir_attaque("Carabaffe", "Mimi-Queue");
CALL pokemon_definir_attaque("Carabaffe", "Pistolet ?? O");
CALL pokemon_definir_attaque("Carabaffe", "Repli");
CALL pokemon_definir_attaque("Carabaffe", "Tour Rapide");
CALL pokemon_definir_attaque("Carabaffe", "Morsure");
CALL pokemon_definir_attaque("Carabaffe", "Vibraqua");
CALL pokemon_definir_attaque("Carabaffe", "Abri");
CALL pokemon_definir_attaque("Carabaffe", "Hydroqueue");
CALL pokemon_definir_attaque("Carabaffe", "Exuviation");
CALL pokemon_definir_attaque("Carabaffe", "Hydrocanon");
CALL pokemon_definir_attaque("Tortank", "Charge");
CALL pokemon_definir_attaque("Tortank", "Mimi-Queue");
CALL pokemon_definir_attaque("Tortank", "Pistolet ?? O");
CALL pokemon_definir_attaque("Tortank", "Repli");
CALL pokemon_definir_attaque("Tortank", "Tour Rapide");
CALL pokemon_definir_attaque("Tortank", "Morsure");
CALL pokemon_definir_attaque("Tortank", "Vibraqua");
CALL pokemon_definir_attaque("Tortank", "Abri");
CALL pokemon_definir_attaque("Tortank", "Hydroqueue");
CALL pokemon_definir_attaque("Tortank", "Exuviation");
CALL pokemon_definir_attaque("Tortank", "Hydrocanon");
CALL pokemon_definir_attaque("Chenipan", "Charge");
CALL pokemon_definir_attaque("Chenipan", "S??cr??tion");
CALL pokemon_definir_attaque("Chenipan", "Piq??re");
CALL pokemon_definir_attaque("Chrysacier", "Armure");
CALL pokemon_definir_attaque("Papilusion", "Armure");
CALL pokemon_definir_attaque("Papilusion", "Charge");
CALL pokemon_definir_attaque("Papilusion", "Piq??re");
CALL pokemon_definir_attaque("Papilusion", "S??cr??tion");
CALL pokemon_definir_attaque("Papilusion", "Tornade");
CALL pokemon_definir_attaque("Papilusion", "Ultrason");
CALL pokemon_definir_attaque("Papilusion", "Poudre Dodo");
CALL pokemon_definir_attaque("Papilusion", "Poudre Toxik");
CALL pokemon_definir_attaque("Papilusion", "Cyclone");
CALL pokemon_definir_attaque("Papilusion", "Lame d'Air");
CALL pokemon_definir_attaque("Aspicot", "Dard-Venin");
CALL pokemon_definir_attaque("Aspicot", "S??cr??tion");
CALL pokemon_definir_attaque("Aspicot", "Piq??re");
CALL pokemon_definir_attaque("Coconfort", "Dard-Venin");
CALL pokemon_definir_attaque("Coconfort", "S??cr??tion");
CALL pokemon_definir_attaque("Coconfort", "Piq??re");
CALL pokemon_definir_attaque("Dardargnan", "Double-Dard");
CALL pokemon_definir_attaque("Dardargnan", "Furie");
CALL pokemon_definir_attaque("Dardargnan", "Fr??n??sie");
CALL pokemon_definir_attaque("Dardargnan", "Poursuite");
CALL pokemon_definir_attaque("Dardargnan", "Puissance");
CALL pokemon_definir_attaque("Dardargnan", "Effort");
CALL pokemon_definir_attaque("Roucool", "Charge");
CALL pokemon_definir_attaque("Roucool", "Jet de Sable");
CALL pokemon_definir_attaque("Roucool", "Tornade");
CALL pokemon_definir_attaque("Roucool", "Vive-Attaque");
CALL pokemon_definir_attaque("Roucool", "Cyclone");
CALL pokemon_definir_attaque("Roucool", "Ouragan");
CALL pokemon_definir_attaque("Roucool", "H??te");
CALL pokemon_definir_attaque("Roucool", "Lame d'Air");
CALL pokemon_definir_attaque("Roucoups", "Charge");
CALL pokemon_definir_attaque("Roucoups", "Jet de Sable");
CALL pokemon_definir_attaque("Roucoups", "Tornade");
CALL pokemon_definir_attaque("Roucoups", "Vive-Attaque");
CALL pokemon_definir_attaque("Roucoups", "Cyclone");
CALL pokemon_definir_attaque("Roucoups", "Ouragan");
CALL pokemon_definir_attaque("Roucoups", "H??te");
CALL pokemon_definir_attaque("Roucoups", "Lame d'Air");
CALL pokemon_definir_attaque("Roucarnage", "Charge");
CALL pokemon_definir_attaque("Roucarnage", "Jet de Sable");
CALL pokemon_definir_attaque("Roucarnage", "Tornade");
CALL pokemon_definir_attaque("Roucarnage", "Vive-Attaque");
CALL pokemon_definir_attaque("Roucarnage", "Cyclone");
CALL pokemon_definir_attaque("Roucarnage", "Ouragan");
CALL pokemon_definir_attaque("Roucarnage", "H??te");
CALL pokemon_definir_attaque("Roucarnage", "Lame d'Air");
CALL pokemon_definir_attaque("M??lof??e", "Charme");
CALL pokemon_definir_attaque("M??lof??e", "Encore");
CALL pokemon_definir_attaque("M??lof??e", "Rugissement");
CALL pokemon_definir_attaque("M??lof??e", "Gravit??");
CALL pokemon_definir_attaque("M??lof??e", "M??tronome");
CALL pokemon_definir_attaque("M??lof??e", "Lilliput");
CALL pokemon_definir_attaque("M??lodelfe", "Charme");
CALL pokemon_definir_attaque("M??lodelfe", "Encore");
CALL pokemon_definir_attaque("M??lodelfe", "Rugissement");
CALL pokemon_definir_attaque("M??lodelfe", "Gravit??");
CALL pokemon_definir_attaque("M??lodelfe", "M??tronome");
CALL pokemon_definir_attaque("M??lodelfe", "Lilliput");
CALL pokemon_definir_attaque("M??lodelfe", "Rayon Lune");
CALL pokemon_definir_attaque("M??lodelfe", "V??u Soin");
CALL pokemon_definir_attaque("Goupix", "Flamm??che");
CALL pokemon_definir_attaque("Goupix", "Entrave");
CALL pokemon_definir_attaque("Goupix", "Vive-Attaque");
CALL pokemon_definir_attaque("Goupix", "Calcination");
CALL pokemon_definir_attaque("Goupix", "Lance-Flammes");
CALL pokemon_definir_attaque("Goupix", "Danse Flamme");
CALL pokemon_definir_attaque("Goupix", "Feu d'Enfer");
CALL pokemon_definir_attaque("Goupix d'Alola", "Flamm??che");
CALL pokemon_definir_attaque("Goupix d'Alola", "Entrave");
CALL pokemon_definir_attaque("Goupix d'Alola", "Vive-Attaque");
CALL pokemon_definir_attaque("Goupix d'Alola", "Calcination");
CALL pokemon_definir_attaque("Goupix d'Alola", "Lance-Flammes");
CALL pokemon_definir_attaque("Goupix d'Alola", "Danse Flamme");
CALL pokemon_definir_attaque("Feunard", "Flamm??che");
CALL pokemon_definir_attaque("Feunard", "Entrave");
CALL pokemon_definir_attaque("Feunard", "Vive-Attaque");
CALL pokemon_definir_attaque("Feunard", "Calcination");
CALL pokemon_definir_attaque("Feunard", "Lance-Flammes");
CALL pokemon_definir_attaque("Feunard", "Danse Flamme");
CALL pokemon_definir_attaque("Feunard", "Feu d'Enfer");
CALL pokemon_definir_attaque("Feunard d'Alola", "Flamm??che");
CALL pokemon_definir_attaque("Feunard d'Alola", "Entrave");
CALL pokemon_definir_attaque("Feunard d'Alola", "Vive-Attaque");
CALL pokemon_definir_attaque("Feunard d'Alola", "Calcination");
CALL pokemon_definir_attaque("Feunard d'Alola", "Lance-Flammes");
CALL pokemon_definir_attaque("Feunard d'Alola", "Danse Flamme");
CALL pokemon_definir_attaque("Feunard d'Alola", "Feu d'Enfer");
CALL pokemon_definir_attaque("Rondoudou", "Berceuse");
CALL pokemon_definir_attaque("Rondoudou", "Boul'Armure");
CALL pokemon_definir_attaque("Rondoudou", "Entrave");
CALL pokemon_definir_attaque("Rondoudou", "Torgnoles");
CALL pokemon_definir_attaque("Rondoudou", "Roulade");
CALL pokemon_definir_attaque("Rondoudou", "Avale");
CALL pokemon_definir_attaque("Rondoudou", "Stockage");
CALL pokemon_definir_attaque("Rondoudou", "Repos");
CALL pokemon_definir_attaque("Rondoudou", "Copie");
CALL pokemon_definir_attaque("Grodoudou", "M??gaphone");
CALL pokemon_definir_attaque("M??lo", "??cras'Face");
CALL pokemon_definir_attaque("M??lo", "Trempette");
CALL pokemon_definir_attaque("M??lo", "Berceuse");
CALL pokemon_definir_attaque("M??lo", "Encore");
CALL pokemon_definir_attaque("M??lo", "Charme");
CALL pokemon_definir_attaque("Toudoudou", "Berceuse");
CALL pokemon_definir_attaque("Toudoudou", "Charme");
CALL pokemon_definir_attaque("Toudoudou", "Boul'Armure");
CALL pokemon_definir_attaque("Toudoudou", "??cras'Face");
CALL pokemon_definir_attaque("Toudoudou", "Doux Baiser");
CALL pokemon_definir_attaque("Nidoran???", "Picpic");
CALL pokemon_definir_attaque("Nidoran???", "Puissance");
CALL pokemon_definir_attaque("Nidoran???", "Double Pied");
CALL pokemon_definir_attaque("Nidoran???", "Dard-Venin");
CALL pokemon_definir_attaque("Nidoran???", "Furie");
CALL pokemon_definir_attaque("Nidoran???", "Koud'Korne");
CALL pokemon_definir_attaque("Nidorino", "Flatterie");
CALL pokemon_definir_attaque("Nidorino", "Picpic");
CALL pokemon_definir_attaque("Nidorino", "Puissance");
CALL pokemon_definir_attaque("Nidorino", "Double Pied");
CALL pokemon_definir_attaque("Nidorino", "Dard-Venin");
CALL pokemon_definir_attaque("Nidorino", "Furie");
CALL pokemon_definir_attaque("Nidorino", "Koud'Korne");
CALL pokemon_definir_attaque("Nidoking", "Picpic");
CALL pokemon_definir_attaque("Nidoking", "Puissance");
CALL pokemon_definir_attaque("Nidoking", "Double Pied");
CALL pokemon_definir_attaque("Nidoking", "Dard-Venin");
CALL pokemon_definir_attaque("Nidoking", "Mania");
CALL pokemon_definir_attaque("Nidoking", "M??gacorne");
CALL pokemon_definir_attaque("Kicklee", "Charge");
CALL pokemon_definir_attaque("Kicklee", "Puissance");
CALL pokemon_definir_attaque("Kicklee", "Ruse");
CALL pokemon_definir_attaque("Kicklee", "Double Pied");
CALL pokemon_definir_attaque("Kicklee", "Balayage");
CALL pokemon_definir_attaque("Kicklee", "Vendetta");
CALL pokemon_definir_attaque("Tygnon", "Bluff");
CALL pokemon_definir_attaque("Tygnon", "Charge");
CALL pokemon_definir_attaque("Tygnon", "Coup d'Main");
CALL pokemon_definir_attaque("Tygnon", "Puissance");
CALL pokemon_definir_attaque("Tygnon", "Ruse");
CALL pokemon_definir_attaque("Tygnon", "Vendetta");
CALL pokemon_definir_attaque("Tauros", "Charge");
CALL pokemon_definir_attaque("Tauros", "Koud'Korne");
CALL pokemon_definir_attaque("Tauros", "Repos");
CALL pokemon_definir_attaque("Tauros", "Poursuite");
CALL pokemon_definir_attaque("Tauros", "B??lier");
CALL pokemon_definir_attaque("Tauros", "Mania");
CALL pokemon_definir_attaque("Tauros", "Damocl??s");
CALL pokemon_definir_attaque("Debugant", "Bluff");
CALL pokemon_definir_attaque("Debugant", "Charge");
CALL pokemon_definir_attaque("Debugant", "Coup d'Main");
CALL pokemon_definir_attaque("Debugant", "Puissance");
CALL pokemon_definir_attaque("Kapoera", "Bluff");
CALL pokemon_definir_attaque("Kapoera", "Charge");
CALL pokemon_definir_attaque("Kapoera", "Coup d'Main");
CALL pokemon_definir_attaque("Kapoera", "Puissance");
CALL pokemon_definir_attaque("Kapoera", "Ruse");
CALL pokemon_definir_attaque("Kapoera", "Vive-Attaque");
CALL pokemon_definir_attaque("Kapoera", "Vendetta");
CALL pokemon_definir_attaque("Kapoera", "Effort");
CALL pokemon_definir_attaque("Muciole", "Charge");
CALL pokemon_definir_attaque("Muciole", "Flash");
CALL pokemon_definir_attaque("Muciole", "Reflet");
CALL pokemon_definir_attaque("Muciole", "Vive-Attaque");
CALL pokemon_definir_attaque("Muciole", "Coup d'Main");
CALL pokemon_definir_attaque("Muciole", "Damocl??s");
CALL pokemon_definir_attaque("Muciole", "Rayon Lune");
CALL pokemon_definir_attaque("Nidoran???", "Picpic");
CALL pokemon_definir_attaque("Nidoran???", "Puissance");
CALL pokemon_definir_attaque("Nidoran???", "Double Pied");
CALL pokemon_definir_attaque("Nidoran???", "Dard-Venin");
CALL pokemon_definir_attaque("Nidoran???", "Furie");
CALL pokemon_definir_attaque("Nidoran???", "Koud'Korne");
CALL pokemon_definir_attaque("Nidorina", "Flatterie");
CALL pokemon_definir_attaque("Nidorina", "Picpic");
CALL pokemon_definir_attaque("Nidorina", "Puissance");
CALL pokemon_definir_attaque("Nidorina", "Double Pied");
CALL pokemon_definir_attaque("Nidorina", "Dard-Venin");
CALL pokemon_definir_attaque("Nidorina", "Furie");
CALL pokemon_definir_attaque("Nidorina", "Koud'Korne");
CALL pokemon_definir_attaque("Nidoqueen", "Picpic");
CALL pokemon_definir_attaque("Nidoqueen", "Puissance");
CALL pokemon_definir_attaque("Nidoqueen", "Double Pied");
CALL pokemon_definir_attaque("Nidoqueen", "Dard-Venin");
CALL pokemon_definir_attaque("Nidoqueen", "Mania");
CALL pokemon_definir_attaque("Nidoqueen", "M??gacorne");
CALL pokemon_definir_attaque("Kangourex", "Bluff");
CALL pokemon_definir_attaque("Kangourex", "Morsure");
CALL pokemon_definir_attaque("Kangourex", "Fr??n??sie");
CALL pokemon_definir_attaque("Kangourex", "Attrition");
CALL pokemon_definir_attaque("Lippoutou", "??cras'Face");
CALL pokemon_definir_attaque("Lippoutou", "Requiem");
CALL pokemon_definir_attaque("Lippoutou", "Torgnoles");
CALL pokemon_definir_attaque("Lippoutou", "Blizzard");
CALL pokemon_definir_attaque("Lippouti", "??cras'Face");
CALL pokemon_definir_attaque("Lippouti", "Doux Baiser");
CALL pokemon_definir_attaque("Lippouti", "Berceuse");
CALL pokemon_definir_attaque("Lippouti", "Psyko");
CALL pokemon_definir_attaque("Lippouti", "Requiem");
CALL pokemon_definir_attaque("Lippouti", "Blizzard");
CALL pokemon_definir_attaque("??cr??meuh", "Charge");
CALL pokemon_definir_attaque("??cr??meuh", "Rugissement");
CALL pokemon_definir_attaque("??cr??meuh", "Boul'Armure");
CALL pokemon_definir_attaque("??cr??meuh", "Patience");
CALL pokemon_definir_attaque("??cr??meuh", "Roulade");
CALL pokemon_definir_attaque("??cr??meuh", "Plaquage");
CALL pokemon_definir_attaque("Leuphorie", "Boul'Armure");
CALL pokemon_definir_attaque("Leuphorie", "Damocl??s");
CALL pokemon_definir_attaque("Leuphorie", "??cras'Face");
CALL pokemon_definir_attaque("Leuphorie", "Rugissement");
CALL pokemon_definir_attaque("Leuphorie", "Torgnoles");
CALL pokemon_definir_attaque("Leuphorie", "B??lier");
CALL pokemon_definir_attaque("Leuphorie", "Berceuse");
CALL pokemon_definir_attaque("Lumivole", "Charge");
CALL pokemon_definir_attaque("Lumivole", "Doux Parfum");
CALL pokemon_definir_attaque("Lumivole", "Charme");
CALL pokemon_definir_attaque("Lumivole", "Vive-Attaque");
CALL pokemon_definir_attaque("Lumivole", "Rayon Lune");
CALL pokemon_definir_attaque("Lumivole", "Encore");
CALL pokemon_definir_attaque("Lumivole", "Flatterie");
CALL pokemon_definir_attaque("Lumivole", "Coup d'Main");
CALL pokemon_definir_attaque("Latias", "Coup d'Main");
CALL pokemon_definir_attaque("Latias", "Dracosouffle");
CALL pokemon_definir_attaque("Latias", "Psyko");
CALL pokemon_definir_attaque("Latias", "Dracochoc");
CALL pokemon_definir_attaque("Latias", "V??u Soin");

CALL pokemon_definir_genre("Bulbizarre", 12.5, 87.5);
CALL pokemon_definir_genre("Herbizarre", 12.5, 87.5);
CALL pokemon_definir_genre("Florizarre", 12.5, 87.5);
CALL pokemon_definir_genre("M??ga-Florizarre", 12.5, 87.5);
CALL pokemon_definir_genre("Salam??che", 12.5, 87.5);
CALL pokemon_definir_genre("Reptincel", 12.5, 87.5);
CALL pokemon_definir_genre("Dracaufeu", 12.5, 87.5);
CALL pokemon_definir_genre("Carapuce", 12.5, 87.5);
CALL pokemon_definir_genre("Carabaffe", 12.5, 87.5);
CALL pokemon_definir_genre("Tortank", 12.5, 87.5);
CALL pokemon_definir_genre("Chenipan", 50.0, 50.0);
CALL pokemon_definir_genre("Chrysacier", 50.0, 50.0);
CALL pokemon_definir_genre("Papilusion", 50.0, 50.0);
CALL pokemon_definir_genre("Aspicot", 50.0, 50.0);
CALL pokemon_definir_genre("Coconfort", 50.0, 50.0);
CALL pokemon_definir_genre("Dardargnan", 50.0, 50.0);
CALL pokemon_definir_genre("Roucool", 50.0, 50.0);
CALL pokemon_definir_genre("Roucoups", 50.0, 50.0);
CALL pokemon_definir_genre("Roucarnage", 50.0, 50.0);
CALL pokemon_definir_genre("M??lof??e", 75.0, 25.0);
CALL pokemon_definir_genre("M??lodelfe", 75.0, 25.0);
CALL pokemon_definir_genre("Goupix", 75.0, 25.0);
CALL pokemon_definir_genre("Goupix d'Alola", 75.0, 25.0);
CALL pokemon_definir_genre("Feunard", 75.0, 25.0);
CALL pokemon_definir_genre("Feunard d'Alola", 75.0, 25.0);
CALL pokemon_definir_genre("Rondoudou", 75.0, 25.0);
CALL pokemon_definir_genre("Grodoudou", 75.0, 25.0);
CALL pokemon_definir_genre("M??lo", 75.0, 25.0);
CALL pokemon_definir_genre("Toudoudou", 75.0, 25.0);
CALL pokemon_definir_genre("Nidoran???", 0.0, 100.0);
CALL pokemon_definir_genre("Nidorino", 0.0, 100.0);
CALL pokemon_definir_genre("Nidoking", 0.0, 100.0);
CALL pokemon_definir_genre("Kicklee", 0.0, 100.0);
CALL pokemon_definir_genre("Tygnon", 0.0, 100.0);
CALL pokemon_definir_genre("Tauros", 0.0, 100.0);
CALL pokemon_definir_genre("Debugant", 0.0, 100.0);
CALL pokemon_definir_genre("Kapoera", 0.0, 100.0);
CALL pokemon_definir_genre("Muciole", 0.0, 100.0);
CALL pokemon_definir_genre("Nidoran???", 100.0, 0.0);
CALL pokemon_definir_genre("Nidorina", 100.0, 0.0);
CALL pokemon_definir_genre("Nidoqueen", 100.0, 0.0);
CALL pokemon_definir_genre("Kangourex", 100.0, 0.0);
CALL pokemon_definir_genre("Lippoutou", 100.0, 0.0);
CALL pokemon_definir_genre("Lippouti", 100.0, 0.0);
CALL pokemon_definir_genre("??cr??meuh", 100.0, 0.0);
CALL pokemon_definir_genre("Leuphorie", 100.0, 0.0);
CALL pokemon_definir_genre("Lumivole", 100.0, 0.0);
CALL pokemon_definir_genre("Latias", 100.0, 0.0);

CALL pokemon_actualiser_evolution("Bulbizarre", "Herbizarre", 16, false);
CALL pokemon_actualiser_evolution("Herbizarre", "Florizarre", 32, false);
CALL pokemon_actualiser_evolution("Florizarre", "M??ga-Florizarre", NULL, true);

CALL pokemon_actualiser_evolution("Salam??che", "Reptincel", 16, false);
CALL pokemon_actualiser_evolution("Reptincel", "Dracaufeu", 36, false);

CALL pokemon_actualiser_evolution("Carapuce", "Carabaffe", 16, false);
CALL pokemon_actualiser_evolution("Carabaffe", "Tortank", 36, false);

CALL pokemon_actualiser_evolution("Chenipan", "Chrysacier", 7, false);
CALL pokemon_actualiser_evolution("Chrysacier", "Papilusion", 10, false);

CALL pokemon_actualiser_evolution("Aspicot", "Coconfort", 7, false);
CALL pokemon_actualiser_evolution("Coconfort", "Dardargnan", 10, false);

CALL pokemon_actualiser_evolution("Roucool", "Roucoups", 18, false);
CALL pokemon_actualiser_evolution("Roucoups", "Roucarnage", 36, false);


CALL pokemon_actualiser_evolution("Nidoran???", "Nidorino", 16, false);
CALL pokemon_actualiser_evolution("Nidorino", "Nidoking", NULL, false);

CALL pokemon_actualiser_evolution("Nidoran???", "Nidorina", 16, false);
CALL pokemon_actualiser_evolution("Nidorina", "Nidoqueen", NULL, false);

CALL pokemon_actualiser_evolution("M??lo", "M??lof??e", NULL, false);
CALL pokemon_actualiser_evolution("M??lof??e", "M??lodelfe", NULL, false);

CALL pokemon_actualiser_evolution("Goupix", "Feunard", NULL, false);

CALL pokemon_actualiser_evolution("Rondoudou", "Grodoudou", NULL, false);

CALL pokemon_actualiser_evolution("Toudoudou", "Rondoudou", NULL, false);
CALL pokemon_actualiser_evolution("Rondoudou", "Grodoudou", NULL, false);

CALL pokemon_actualiser_evolution("Goupix d'Alola", "Feunard d'Alola", NULL, false);
