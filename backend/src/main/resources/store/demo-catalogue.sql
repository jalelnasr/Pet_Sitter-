-- Catalogue fictif de la boutique, inséré seulement si la table products est vide.

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('croq-chat','Croquettes chat stérilisé','Félin+','nourriture','Recette au poulet pour chats stérilisés, riche en protéines et pauvre en matières grasses. Aide à maintenir un poids de forme.',0,0,NULL,'Meilleure vente','bag','#0F5534','#E3F1E7','cat',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('croq-chat','chat');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('croq-chat','2 kg',49,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('croq-chat','4 kg',89,50,1,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('croq-chat','8 kg',165,50,2,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('croq-chat',0,'Composition','Poulet (32 %), riz, pois, pulpe de betterave');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('croq-chat',1,'Âge','Adulte, dès 1 an');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('croq-chat',2,'Fabriqué','En Tunisie');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('patee-chat','Pâtée au poulet · lot de 12','Félin+','nourriture','Émincés en sauce, sans colorant. Un sachet le soir en complément des croquettes.',0,0,NULL,NULL,'can','#C0623B','#F7E6DE','cat',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('patee-chat','chat');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('patee-chat','12 × 85 g',32,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('patee-chat','24 × 85 g',59,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('patee-chat',0,'Composition','Poulet (40 %), bouillon, minéraux');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('patee-chat',1,'Âge','Adulte');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('croq-chien','Croquettes chien adulte','Canis','nourriture','Agneau et riz pour chiens de taille moyenne. Croquette adaptée à la mâchoire.',0,0,89,'−10 %','bag','#C0623B','#F7E6DE','dog',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('croq-chien','chien');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('croq-chien','4 kg',79,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('croq-chien','12 kg',199,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('croq-chien',0,'Composition','Agneau (26 %), riz, maïs, huile de poisson');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('croq-chien',1,'Taille','Moyen (10–25 kg)');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('graines','Mélange de graines inséparables','Plume','nourriture','Millet, alpiste et graines de tournesol décortiquées pour perruches et inséparables.',0,0,NULL,NULL,'bag','#E9A512','#FDF1D2','bird',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('graines','oiseau');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('graines','1 kg',14,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('graines','3 kg',36,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('graines',0,'Composition','Millet jaune et rouge, alpiste, avoine, tournesol');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('foin','Foin de prairie de Bizerte','Terroir','nourriture','Foin de seconde coupe, long et parfumé, récolté dans la région de Bizerte.',0,0,NULL,'Local','bag','#B08850','#F3EADC','rabbit',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('foin','lapin');
INSERT INTO product_species (product_id,species) VALUES ('foin','autre');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('foin','1 kg',9,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('foin','3 kg',24,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('foin',0,'Origine','Bizerte, Tunisie');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('foin',1,'Pour','Lapins, cochons d''Inde');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('flocons','Flocons poissons d''eau douce','Aqua','nourriture','Flocons complets pour poissons rouges et poissons tropicaux. Ne trouble pas l''eau.',0,0,NULL,NULL,'tub','#2F6E8F','#E0EDF3','fish',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('flocons','poisson');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('flocons','100 ml',12,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('flocons','250 ml',25,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('flocons',0,'Dosage','Une pincée, une fois par jour');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('arbre','Arbre à chat 120 cm','Maison Miaou','accessoires','Trois niveaux, griffoirs en sisal et niche douillette. Montage en 15 minutes.',0,0,NULL,NULL,'object','#7A4A7E','#EFE4F0','houseLine',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('arbre','chat');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('arbre','Beige',189,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('arbre','Gris',189,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('arbre',0,'Dimensions','50 × 40 × 120 cm');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('arbre',1,'Matières','Bois, sisal, peluche');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('laisse','Laisse et collier réglables','Balade','accessoires','Sangle rembourrée et mousqueton en acier. Bande réfléchissante pour les promenades du soir.',0,0,NULL,NULL,'object','#0F5534','#E3F1E7','footprints',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('laisse','chien');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('laisse','S',35,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('laisse','M',39,50,1,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('laisse','L',42,50,2,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('laisse',0,'Longueur','1,5 m');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('laisse',1,'Tour de cou','S 25–35 · M 35–45 · L 45–60 cm');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('fontaine','Fontaine à eau 2 L','Source','accessoires','Eau filtrée en continu, silencieuse. Encourage les chats à boire davantage.',0,0,NULL,NULL,'object','#2F6E8F','#E0EDF3','drop',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('fontaine','chat');
INSERT INTO product_species (product_id,species) VALUES ('fontaine','chien');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('fontaine','2 L',69,50,0,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('fontaine',0,'Filtre','À changer toutes les 4 semaines');
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('fontaine',1,'Câble','USB');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('balle','Balle à mâcher résistante','Joyeux','jouets','Caoutchouc naturel, flotte dans l''eau. Idéale pour la plage de La Marsa.',0,0,NULL,NULL,'object','#E9A512','#FDF1D2','tennisBall',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('balle','chien');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('balle','Ø 6 cm',15,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('balle','Ø 8 cm',19,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('balle',0,'Matière','Caoutchouc naturel');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('cage','Cage pour oiseaux 60 cm','Plume','accessoires','Livrée avec deux perchoirs en bois, mangeoires et fond amovible.',0,0,NULL,NULL,'object','#E9A512','#FDF1D2','bird',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('cage','oiseau');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('cage','60 cm',145,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('cage','80 cm',195,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('cage',0,'Dimensions','60 × 40 × 70 cm');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('litiere','Litière végétale agglomérante','Nature','hygiene','Fibres végétales compostables, sans poussière. Contrôle des odeurs pendant 2 semaines.',0,0,NULL,NULL,'bag','#B08850','#F3EADC','leaf',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('litiere','chat');
INSERT INTO product_species (product_id,species) VALUES ('litiere','lapin');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('litiere','10 L',22,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('litiere','20 L',39,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('litiere',0,'Durée','Environ 3 semaines pour un chat');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('aquarium','Kit aquarium 30 L','Aqua','accessoires','Bac en verre avec filtre, éclairage LED programmable et couvercle.',0,0,NULL,NULL,'object','#2F6E8F','#E0EDF3','waves',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('aquarium','poisson');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('aquarium','30 L',159,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('aquarium','60 L',249,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('aquarium',0,'Inclus','Filtre, éclairage, thermomètre');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('coussin','Coussin douillet lavable','Maison Miaou','accessoires','Rembourrage moelleux, housse amovible lavable à 30 °C.',0,0,NULL,NULL,'object','#7A4A7E','#EFE4F0','bed',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('coussin','chat');
INSERT INTO product_species (product_id,species) VALUES ('coussin','chien');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('coussin','S · 50 cm',59,50,0,TRUE);
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('coussin','M · 70 cm',79,50,1,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('coussin',0,'Housse','Coton, lavable en machine');

INSERT INTO products (id,name,brand,category,description,rating,reviews,old_price,badge,pack_kind,color,tint,icon,created_at,updated_at,active) VALUES ('shampooing','Shampooing doux à l''aloe vera','Nature','hygiene','pH adapté à la peau des animaux, sans parfum agressif.',0,0,NULL,NULL,'tub','#0F5534','#E3F1E7','bathtub',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE);
INSERT INTO product_species (product_id,species) VALUES ('shampooing','chien');
INSERT INTO product_species (product_id,species) VALUES ('shampooing','chat');
INSERT INTO product_options (product_id,label,price,stock,sort_order,active) VALUES ('shampooing','250 ml',24,50,0,TRUE);
INSERT INTO product_details (product_id,sort_order,detail_label,detail_value) VALUES ('shampooing',0,'Usage','Une fois par mois');
