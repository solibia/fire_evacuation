/**
* Name: mstp6PAZIMNASolibia
* Author: basile
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model mstp6PAZIMNASolibia

global {
	/** Insert the global definitions, variables and actions here */
	shape_file shape_file_panneau <- shape_file('../includes/panneau.shp');
	shape_file shape_file_exit <- shape_file('../includes/exit.shp');	
	shape_file shape_file_plateform <- shape_file('../includes/plateform.shp');	
	
	geometry shape <- envelope(shape_file_plateform);

	init {
		create Panneau from: shape_file_panneau;
		create Exit from: shape_file_exit;
		create Plateform from: shape_file_plateform;
		create Gens number: 15{
			set location <- any_location_in( one_of(Exit));
			set exit <- one_of(Exit);			
		}
		create Sonneur number: 4{}	
		create Feux number: 1{}		
	}
}

species Plateform {
	rgb color <- #black;
	aspect basic {
		draw shape color: color;
	}
}

species Exit {
	rgb color <- #green;
	
	aspect basic {
		draw shape color: color;
	}
}

species Panneau {
	rgb color <- #yellow;
	Exit exit;
	
	aspect basic {
		draw shape color: color;
	}
}

species Platforme {
	rgb color <- #black;
	
	aspect basic {
		draw shape color: color;
	}
}

species Sonneur {
	point location;
	rgb couleur;
	float size;
	float rayon_detect <- rnd(30)+5.0;
	int current_ring <- 0;
	float max_ring <- rnd(5)+5.0;
	
	reflex detect_feux when: (current_ring=0){
		//compter le feux dans rayon_detect
		list listFeux <- list (Feux) where (each distance_to self < rayon_detect);		
		if(length(listFeux) > 0){
			do sonner;
		}
	} 
	action sonner{
		//initialiser current_ring par 1
		current_ring <- 1;
	}
	
	reflex sonner when:(current_ring > 0){
		current_ring <- current_ring + 1; //augmenter
		if(current_ring >= max_ring){
			//remettre current_rng à 0
			current_ring <- 0;
		}
	}
	
	aspect basic {
		draw circle(size) color:couleur;
	}	
}

species Feux {
	//point location;
	rgb couleur <- #red;
	float size <- 1.0;
	float rayon_affect <- rnd(3*size)+1.5;
	float propagation_speed <- rnd(rayon_affect)+1.0;
	float age;
	float max_age <- 200.0;
	float generate_smock_speed;
	
	reflex bruler {
		age <- age + 1; //Augmenter
		if(age >= max_age){
			//il est mort
			do die;
		}
		//Infuencer sur les gens
		//compter les gens dans le rayon_affect	
		list listGens <- list (Gens) where (each distance_to self < rayon_affect);		
		if(length(listGens)>0){
			ask listGens {
			//diminuer la puissance
			current_power <- current_power - 1;
				if(current_power <=0){
					do die;
				}
			}
		}
	}
	
	reflex propagation when: ((age/propagation_speed) =0){
		//creer un feux à coter
		create Feux number:1{
			size  <- max([self.size-1,1]);
			location  <- self.location+1;
			couleur <- self.couleur;
		}
	}
	
	aspect basic {
		draw circle(size) color:couleur;
	}	
}

species Gens skills:[moving]{
	point location;
	rgb couleur <- #white;
	float size <- 2.0;
	int status <- 0;
	float propagation_speed;
	float speed <- rnd(5)+1.0;
	Exit exit;
	float rayon_observation <- rnd(10)+propagation_speed;
	float current_power <- rnd(1000)+500+1.0;
	
	reflex normal_moving when:(status=0){
		//se deplacer par hazard
		do action: wander amplitude: 180;		
		//observer le feux
		//compter les feux dans rayon_observation
		list listFeux <- list (Feux) where (each distance_to self < rayon_observation);				
		if(length(listFeux) > 0){
			do goto target: exit.location speed:speed;
			status <- 1;
		}
	}
	
	reflex evacuer when:(status=1){
		do goto target: exit speed:speed;
		//observer les exits
		//compter les exits
		list listExit <- list (Exit) where (each distance_to self < rayon_observation);						
		if(length(listExit) > 0){
			exit <- first(listExit);  //ce qui est observé
		}
		//observer les panneaux
		//compter les panneaux dans rayon_observation
		list listPanneaux <- list (Panneau) where (each distance_to self < rayon_observation);						
		if(length(listPanneaux) > 0){
			exit <- first(listPanneaux).exit; //ce qui indique par le panneau
		}
		//Observer les sonneurs
		//compter les sonneurs dans rayon_observation
		list listSonneurs <- list (Sonneur) where (each distance_to self < rayon_observation);
		ask listSonneurs {
			if(current_ring=0){
				do sonner;
			}
		}
	}
	aspect basic {
		draw circle(size) color:couleur;
	}
}



experiment mstp6PAZIMNASolibia type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display mstp6PAZIMNASolibia {
			species Plateform aspect: basic;
			species Exit aspect: basic;
			species Panneau aspect: basic;
			species Sonneur aspect: basic;
			species Feux aspect: basic;
			species Gens aspect: basic;
		}
	}
}
