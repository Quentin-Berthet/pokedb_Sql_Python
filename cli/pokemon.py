#!/usr/bin/env python3

__authors__ = ["Baptiste Coudray", "Quentin Berthet", "Kennett Torres"]
__date__ = "14.06.2020"
__course__ = "SBD"
__description__ = "Pokemon CLI"

import mysql.connector
import pandas
from pandas import DataFrame


def pandas_config():
    pandas.set_option('display.max_rows', None)
    pandas.set_option('display.max_columns', None)
    pandas.set_option('display.width', None)


def connect_db():
    try:
        return mysql.connector.connect(
            host="localhost",
            user="pokecli",
            password="pokecli123",
            database="pokedb"
        )
    except Exception as e:
        print(f"{e}")
        exit(1)


def find_pokemon_with_id_one(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT Nom, Region, Route FROM Pokemon INNER JOIN Localisation L on Pokemon.Id = L.IdPokemon WHERE Id = 1")
    print(DataFrame(cursor.fetchall(), columns=["Nom", "Region", "Route"]))


def find_pokemon_with_seed_category_and_plant_type_and_fire_weakness(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT Nom, Categorie, T.Type, F.Type  FROM Pokemon INNER JOIN Categorisation C ON Pokemon.Id = C.IdPokemon INNER JOIN Typage T ON Pokemon.Id = T.IdPokemon INNER JOIN Faiblesse F ON Pokemon.Id = F.IdPokemon WHERE F.Type = 'Feu' AND C.Categorie = 'Graine' AND T.Type = 'Plante'"
    )
    print(DataFrame(cursor.fetchall(), columns=["Nom", "Categorie", "Type", "Faiblesse"]))


def find_pokemon_on_road_154_with_no_evolution(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT Id, Nom, Taille, Poids, ExperienceMinimum, ExperienceMaximum FROM `Pokemon` INNER JOIN Localisation L on Pokemon.Id = L.IdPokemon WHERE Evolution IS NULL AND Route = 154")
    print(DataFrame(cursor.fetchall(),
                    columns=["Id", "Nom", "Taille", "Poids", "ExperienceMinimum", "ExperienceMaximum"]))


def find_all_cities_of_hoenn(db):
    cursor = db.cursor()
    cursor.execute("SELECT Nom FROM Ville WHERE Region = 'Hoenn'")
    print(DataFrame(cursor.fetchall(), columns=["Nom"]))


def count_number_of_roads_in_johto(db):
    cursor = db.cursor()
    cursor.execute("SELECT COUNT(*) FROM Ville WHERE Region = 'Johto'")
    print(DataFrame(cursor.fetchall(), columns=["Total"]))


def find_female_pokemon_with_charge_attack_on_road_87(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT Nom, Sexe, Pourcentage, Technique, Route FROM Pokemon INNER JOIN Genre G on Pokemon.Id = G.IdPokemon INNER JOIN Attaque A on Pokemon.Id = A.IdPokemon INNER JOIN Localisation L on Pokemon.Id = L.IdPokemon WHERE G.Sexe = 'Femelle' AND G.Pourcentage > 0.0 AND L.Route = 87 AND A.Technique = 'Charge'")
    print(DataFrame(cursor.fetchall(), columns=["Nom", "Sexe", "Pourcentage", "Technique", "Route"]))


def find_pokemon_with_type_plant_and_mega_evolution(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT Id, Nom, T.Type FROM `Pokemon` INNER JOIN Typage T ON Pokemon.Id = T.IdPokemon WHERE Pokemon.Mega = True AND T.Type = 'Plante'")
    print(DataFrame(cursor.fetchall(), columns=["Id", "Nom", "Type"]))


def find_technique_type_tenebres_and_power_over_50(db):
    cursor = db.cursor()
    cursor.execute("SELECT Intitule FROM Technique WHERE Specialisation = 'Ténèbres' AND Puissance > 50")
    print(DataFrame(cursor.fetchall(), columns=["Nom"]))


def count_pokemon_just_female(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT COUNT(Id) FROM Pokemon INNER JOIN Genre G on Pokemon.Id = G.IdPokemon WHERE G.Sexe = 'Femelle' AND G.Pourcentage = 100.0 ")
    print(DataFrame(cursor.fetchall(), columns=["Total"]))


def count_pokemon_type_fire(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT COUNT(Id) FROM Pokemon INNER JOIN Typage T ON Pokemon.Id = T.IdPokemon WHERE T.Type = 'Feu' ")
    print(DataFrame(cursor.fetchall(), columns=["Total"]))


def count_all_categories(db):
    cursor = db.cursor()
    cursor.execute("SELECT COUNT(Intitule) FROM Categorie")
    print(DataFrame(cursor.fetchall(), columns=["Total"]))


def display_pokemon_male_with_id_max(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT MAX(Id) FROM Pokemon INNER JOIN Genre G on Pokemon.Id = G.IdPokemon WHERE G.Sexe = 'Mâle' AND G.Pourcentage > 0.0")
    print(DataFrame(cursor.fetchall(), columns=["Id"]))


def display_pokemon_type_water_category_carapace_with_id_min(db):
    cursor = db.cursor()
    cursor.execute(
        "SELECT MIN(Id) FROM Pokemon INNER JOIN Categorisation C ON Pokemon.Id = C.IdPokemon INNER JOIN Typage T ON Pokemon.Id = T.IdPokemon WHERE C.Categorie = 'Carapace' AND T.Type = 'Eau' ")
    print(DataFrame(cursor.fetchall(), columns=["Id"]))


def find_pokemon_name_start_with_n_and_limit_weight(db):
    cursor = db.cursor()
    cursor.execute("SELECT Id, Nom, Poids FROM Pokemon WHERE Nom LIKE 'N%' AND Poids BETWEEN 15.0 AND 50.0")
    print(DataFrame(cursor.fetchall(), columns=["Id", "Nom", "Poids"]))


if __name__ == '__main__':
    pandas_config()
    db = connect_db()
    requests = [
        ("Lister les attributs et les routes où on peut trouver le Pokémon avec l’id 1.", find_pokemon_with_id_one),
        ("Lister tous les Pokémon de catégorie ”Graine” et de type ”Plante” qui ont une faiblesse contre le \"Feu\".",
         find_pokemon_with_seed_category_and_plant_type_and_fire_weakness),
        ("Lister tous les Pokémon de la route 154 qui n’ont pas d’évolution.",
         find_pokemon_on_road_154_with_no_evolution),
        ("Lister toutes les villes de la région \"Hoenn\".", find_all_cities_of_hoenn),
        ("Compter le nombre de routes dans la région de \"Johto\".", count_number_of_roads_in_johto),
        ("Compter le nombre de Pokémon de type \"Feu\".", count_pokemon_type_fire),
        ("Compter le nombre de catégories.", count_all_categories),
        ("Afficher le Pokémon mâle avec l'id le plus haut.", display_pokemon_male_with_id_max),
        ("Compter le nombre de pokemon exclusivement femelle.", count_pokemon_just_female),
        ("Trouver les Pokemon qui commence par la lettre \"N\" et qui pèse entre 15 et 50 kg.",
         find_pokemon_name_start_with_n_and_limit_weight),
        ("Afficher le Pokémon de type \"Eau\" de catégorie \"Carapace\" avec l'id le plus petit.",
         display_pokemon_type_water_category_carapace_with_id_min),
        ("Lister tous les Pokémon de type \"Plante\" avec une méga-évolution.",
         find_pokemon_with_type_plant_and_mega_evolution),
        ("Lister toutes les techniques de type \"Ténèbres\" avec une \"Puissance\" supérieur à 50.",
         find_technique_type_tenebres_and_power_over_50),
        ("Lister tous les Pokémon femelles ayant comme attaque \"Charge\" et se trouvant sur la route 87.",
         find_female_pokemon_with_charge_attack_on_road_87)
    ]
    while True:
        for i in range(len(requests)):
            desc, _ = requests[i]
            print(f"{i + 1} - {desc}")
        try:
            choice = int(input(f"Quelle requête exécuter ? (1-{len(requests)})"))
            if 0 < choice <= len(requests):
                print("")
                requests[choice - 1][1](db)
                print("")
        except ValueError:
            continue
        except (EOFError, KeyboardInterrupt):
            exit(0)
