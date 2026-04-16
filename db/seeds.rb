# Idempotent seeds — safe to run multiple times.

# Admin user
admin = User.find_or_create_by!(email: "admin@entretouteslesfemmes.fr") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.admin = true
end

# Themes
qui_suis_je     = Theme.find_or_create_by!(name: "Qui suis-je ?")
coin_des_mamans = Theme.find_or_create_by!(name: "Le coin des mamans")
grain_a_moudre  = Theme.find_or_create_by!(name: "Du grain à moudre")
oeuvre_art      = Theme.find_or_create_by!(name: "Une œuvre d'art à savourer")

# Lettre 36 — dimanche 16 juin 2024
lettre36 = Newsletter.find_or_create_by!(number: 36) do |n|
  n.published_on        = Date.new(2024, 6, 16)
  n.liturgical_context  = "11e dimanche du Temps Ordinaire"
end

post1 = Post.find_or_create_by!(title: "Moi et les autres", theme: qui_suis_je) do |p|
  p.user       = admin
  p.newsletter = lettre36
end
post1.content = <<~HTML
  <p>« Le cortège passait et j'y cherchais mon corps<br>
  Tous ceux qui survenaient et n'étaient pas moi-même<br>
  Amenaient un à un les morceaux de moi-même<br>
  On me bâtit peu à peu comme on élève une tour »</p>

  <p><em>Guillaume Apollinaire (1913), « Cortège », Alcools</em></p>

  <p>Puisqu'il faut penser avec le corps humain, et non contre lui, ou malgré lui, nous devons bien nous rendre à l'évidence : devant la réalité du corps humain, l'individualisme en tant que courant de pensée ne peut tenir.</p>

  <p>Nous entendons ici individualisme au sens courant, comme une manière de penser qui place l'individu au centre, et en second ses relations aux autres, conviés comme des conséquences de ses choix. Dans un mode de pensée individualiste, mon identité ne m'est pas conférée par les liens qui me relient aux autres. Elle vient uniquement de ce que je choisis pour moi. Je suis ce que je veux être, ce que je choisis d'être ; je peux refuser ce qui m'a été donné.</p>

  <p>Le soupçon plane : recevoir ce que je n'ai pas choisi, que je m'y résigne ou au contraire que je veuille l'embrasser à pleines mains, cela met de toute façon ma liberté en danger. Au fond ma liberté n'est vraiment elle-même que si je suis d'abord seul, et fais intervenir les autres en second.</p>

  <p>Du point de vue de la morale, c'est une position bien frêle : pas question ici de me tenir face à un « prochain », qui pourrait avoir besoin de moi, et que je ferais justement passer avant moi, ni même d'un « autrui » qui m'oblige par sa présence à me reconnaître en lui. Il y a moi, et puis, il y a les autres. Et le fossé est grand entre les deux.</p>

  <p>Or, il y a le corps des femmes. Qui ne peut être complet que s'il est constitué d'organes prévus pour qu'y vive un autre – un enfant.</p>

  <p>Dire que l'être humain est un être de relation, que cela est marqué dans son corps, que la sexualité est le lieu où se révèle la destination relationnelle des personnes – toutes ces phrases ne sont pas de vaines formules creuses.</p>

  <p>Il suffit de regarder comme est fait le corps des femmes. Il est fait pour que d'autres puissent vivre. Est-ce que cela ne dit pas de manière littérale, explicite, que nous ne sommes rien les uns sans les autres ? Est-ce que nous ne sommes pas aveuglés par la réfutation vivante de l'individualisme qu'est le corps d'une femme enceinte ? Ne voyons-nous pas que refuser de reconnaître sa propre dépendance à l'égard des autres entame et fait craquer la toile que nous formons tous ensemble ?</p>

  <p>Si l'on observe les choses du point de vue de l'enfant, sa venue au monde dépend d'une relation asymétrique. L'enfant ne peut rien pour lui-même, il reçoit tout : il ne choisit pas sa venue au monde, ni la mère qui le porte, ni le père qui l'engendre… Son identité, il la reçoit, avant de pouvoir la construire.</p>

  <p>Et si l'on se place du point de vue de la femme ? La maternité offre aussi à la femme la possibilité d'acquérir une nouvelle identité par l'intermédiaire d'un autre. Ou plutôt, de deux autres. La mère devient mère grâce à deux intermédiaires : le père et l'enfant.</p>

  <p>Lorsque je deviens mère, quelque chose de moi-même m'est donné par un autre.</p>

  <p>Ce que d'autres ont permis que je devienne, me faut-il le rejeter ? Est-ce que cela met en danger celle que je suis ? Cette mère que je suis devenue, et que je n'étais pas, ce n'est pourtant pas quelqu'un d'autre : c'est bien moi. J'y ai gagné puisque j'ai découvert de nouvelles possibilités d'élargir mon être.</p>

  <p>Le corps des femmes manifeste ce qui marque l'expérience humaine à la base : il y a toujours quelque chose de moi-même qui m'est donné par d'autres.</p>
HTML
post1.save!

post2 = Post.find_or_create_by!(title: "Faisons des œuvres d'art leurs souvenirs d'enfance !", theme: coin_des_mamans) do |p|
  p.user       = admin
  p.newsletter = lettre36
end
post2.content = <<~HTML
  <p>Chères mamans,</p>

  <p>Vous souvenez-vous de cet adage qui vous était proposé dans les premières Lettres ?</p>

  <p><strong>« Faisons des œuvres d'art leurs souvenirs d'enfance ! »</strong></p>

  <p>L'idée est simple : la Reine des Neiges, la Pat' Patrouille, les Disney, Barbie, etc., vous n'y échapperez pas — vos enfants y ont accès le plus aisément du monde. Et même si vous avez banni cela de chez vous, ils en entendent au moins parler par l'école, les copains. Cela ne demande aucun effort à personne : quoi qu'on veuille, ils sont et seront familiers de cette culture.</p>

  <p>Mais la culture que l'on regarde comme savante, si vous voulez la leur transmettre, alors cela vous demande un effort, certes, mais c'est un immense cadeau que vous leur faites.</p>

  <p>Vous direz : il y a bien l'école, non ? Mais l'école ne pourra pas forcément le faire pour eux. Entre autres parce que ce qu'on apprend à l'école, on ne l'aime pas forcément, on le regarde comme quelque chose d'étranger. Alors que ce qui vient de la maison, on l'aime d'amour parce qu'on a grandi avec.</p>

  <p>Pourquoi pas créer dès l'enfance ce même lien affectif avec des œuvres d'art ? On les aime, parce qu'elles ont fait partie de notre enfance. Et en échange, elles nous enrichissent à l'intérieur.</p>

  <p>Voici une nouvelle idée de mise en pratique de cet adage. Et si vous leur lisiez un peu la Bible ? Pas la Bible illustrée pour les enfants. Mais la vraie Bible, celle qui fait des milliers de pages, celle qu'on lit à la messe.</p>

  <p>Il y a notamment dans l'Ancien Testament des livres courts, qui se lisent rapidement, dont l'histoire est prenante et que des enfants peuvent écouter jusqu'au bout. Prenez le livre de Jonas. Génial, Jonas. Dieu lui dit d'aller à Ninive, et Jonas s'en va dans la direction opposée. Déjà ça c'est drôle ! Il prend le bateau : bim, tempête. On le jette à la mer, Dieu envoie un poisson pour l'avaler. Ne sentez-vous pas comme on est là dans l'atmosphère merveilleuse des contes, où le monde est à la fois normal et pourtant si étrange ? Formidable pour l'imaginaire. Et puis après la lecture, la petite leçon de catéchisme est servie sur un plateau.</p>

  <p>Vous tentez la chose cette semaine ? 🐟</p>

  <p><em>Joseph Vernet, Jonas et la baleine (1753) — collections.mba-lyon.fr</em></p>
HTML
post2.save!

post3 = Post.find_or_create_by!(title: "Le Cantique des Cantiques (Ct 1, 9-17)", theme: grain_a_moudre) do |p|
  p.user       = admin
  p.newsletter = lettre36
end
post3.content = <<~HTML
  <p><em>Par le p. Florent Urfels, prêtre de Paris</em></p>

  <p>Cette rubrique nous propose une lecture originale du Cantique des Cantiques. À vos Bibles !</p>

  <p>Salomon fait irruption, sans crier gare, dans les v. 9-11, et c'est une magnifique nouvelle ! Alors que Shulamith réfléchissait encore, par un dialogue intérieur, à la dure nécessité de vivre jusqu'au bout la peine de l'Exil, elle découvre que Celui dont la présence n'est normalement accessible qu'en Terre Sainte l'a accompagnée à Babylone. Cette thèse, qui relativise de nombreuses données de la religion traditionnelle d'Israël – notamment la connexion nécessaire de la prière au culte sacrificiel pratiqué à Jérusalem – est l'œuvre d'Ézéchiel (1,1-3 ; 10,18-19 ; 11,22-23). Au creuset de la souffrance, le prophète exilé arrive en effet à l'extraordinaire conviction qu'un sanctuaire de pierres n'est utile au culte que parce qu'il symbolise une vérité autrement profonde : Dieu lui-même abrite en son sein l'homme qui prie, il lui sert lui-même de sanctuaire !</p>

  <p>« Ainsi parle le Seigneur Dieu : Oui, je les ai éloignés parmi les nations ; oui, je les ai dispersés dans les pays étrangers. Mais j'ai été pour eux comme un sanctuaire, dans les pays où ils sont allés. » (Ez 11,16)</p>

  <p>Et que dit Salomon à sa bien-aimée ? Des paroles qui corroborent son cri initial : « je suis noire mais pourtant belle » (v. 5). Alors que Shulamith est toujours aliénée, toujours humiliée, maltraitée et moquée par des Babyloniens arrogants (cf. Ps 136), son Seigneur atteste son irrésistible beauté. Elle a des fers aux pieds et elle entend : « Quel charme, tes joues entre tes boucles, ton cou entre les perles ! » (v. 10) Et il ne s'agit pas d'un compliment consolant mais illusoire, bien plutôt d'une promesse par laquelle Dieu s'engage à faire revenir son peuple sur sa terre.</p>

  <p>Ainsi encouragée par Salomon, Shulamith évoque aux v. 12-14 l'intimité retrouvée au lieu même de l'Exil. La plupart des verbes sont au temps présent car c'est dès maintenant, au creux de son aliénation, que la femme ressent la proximité du bien-aimé. Elle compare celui-ci à « un rameau de cypre parmi les vignes d'Enn-Guèdi » (v. 14), ce qui évoque la fuite de David loin de la colère de Saül (1 S 23,29). Grâce à des cours d'eau souterrains alimentés par les pluies d'hiver, Enn-Guédi est un lieu paradisiaque, avec une végétation foisonnante, entourée par la nature vide et hostile de la mer Morte. David s'y rendait pour ne pas mourir et il comprit que, de la mort, Dieu fait surgir la vie. Shulamith vit une expérience très similaire. Quand on a Dieu avec soi, un environnement mortel ne compte guère.</p>

  <p>Dans ses bouleversantes <em>Lettres de Westerbork</em>, Etty Hillesum raconte comment sa foi retrouvée lui donnait, au sein de l'horreur la plus inhumaine, une immense sérénité, jamais éprouvée auparavant dans des conditions de vie infiniment plus confortables. Ce contraste saisissant correspond bien à la vérité spirituelle que le Cantique veut nous transmettre dans son premier Chant.</p>

  <p>Un seuil supplémentaire est franchi dans les v. 15-17 car un véritable dialogue s'instaure entre les deux partenaires (Salomon au v. 15, Shulamith aux v. 16-17). Assez étrangement, c'est la seule fois où cette forme littéraire est mobilisée dans le Cantique. Salomon chante la beauté de Shulamith : « Ah ! Que tu es belle, mon amie ! » (v. 15) et Shulamith fait de même pour Salomon : « Ah ! Que tu es beau, mon bien-aimé ! » (v. 16). Alors que Salomon commence, quoique avec pudeur, à décrire le corps de Shulamith (« tes yeux sont des colombes »), Shulamith se focalise sur leur demeure commune — évoquant irrésistiblement le Temple construit par Salomon (cf. 1 R 5,8). Même si Dieu ne dédaigne pas de rencontrer son peuple en dehors de tout cadre cultuel, cela ne doit pas devenir la règle liturgique mais plutôt entretenir l'espérance d'un retour à la normale.</p>
HTML
post3.save!

post4 = Post.find_or_create_by!(title: "Les Moulins de mon cœur, de Michel Legrand (1968)", theme: oeuvre_art) do |p|
  p.user       = admin
  p.newsletter = lettre36
end
post4.content = <<~HTML
  <p><em>Repris par Coline Rio (2022)</em></p>

  <p>Michel Legrand ne laisse pas indifférent : généralement on l'aime, ou on le déteste. Si vous ne le connaissez pas du tout, on vous offre ici l'occasion de vous faire un avis.</p>

  <p>« Les Moulins de mon cœur » est l'une de ses chansons les plus connues, reprise par de nombreux artistes dès sa sortie et encore aujourd'hui. Écrite à l'origine en anglais (« The Windmills of Your Mind »), pour la bande originale du film <em>L'Affaire Thomas Crown</em> (1968), la chanson est une romance longue et nostalgique.</p>

  <p>Inspirée de l'andante de la symphonie concertante pour violon et alto K 364 de Mozart, elle a obtenu l'Oscar de la meilleure chanson originale en 1969.</p>

  <p>Qu'est-ce qu'on aime ici ?</p>

  <ul>
    <li>La mélodie qui se déroule comme en une spirale infinie, un mouvement circulaire perpétuel : tout tourne autour de nous, et quand la chanson est finie, on n'a qu'une envie, c'est de la remettre au début ;</li>
    <li>Pour le texte, l'impression d'être plongé dans un flux de conscience, un tournis, dans des pensées qui ne cessent de revenir, de se reformuler – comme celles que l'on peine à chasser au moment de s'endormir ;</li>
    <li>La voix labile, précise et délicate de la chanteuse, dédoublée entre les lacets de mélodie principale et les notes distinctes de l'accompagnement, qui nous transmet la nostalgie avec retenue.</li>
  </ul>

  <p><em>Merci à Caroline B. pour cette idée d'œuvre d'art à savourer !</em></p>
HTML
post4.save!

puts "Seed terminé : #{Newsletter.count} lettres, #{Theme.count} thèmes, #{Post.count} articles, #{User.count} utilisateurs."
