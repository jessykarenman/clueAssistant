/********************************************************************************
CS 312 - Clue Assistant
Partners:
Anthony Nixon
n7u7
38705109

Jessica Johnson
k4g7
34709097

To start the program type: Start.
Please end all inputs with a full stop: .
If the program quits prematurely, enter continue to reach the options menu again.

----Features----

All cards are assigned a probability, 
0 is unknown, could be in envelope,
As the value gets higher it is more likely to not be in the envelope,
1 is definitely known to not be in envelope.

You are player 1, players are assigned a numerical value starting from your left and going around the circle.

Option 1: Displays the current recommended move
The move suggests a trio of cards that have minimum probabilities in their respective categories, excluding cards with probability 1.

Option 2: Enter the card discovered from your turn or let the program know that no one showed you a card

Option 3: Let the program know what room you are in or that you are leaving

Option 4: Enter an opponents guess and which player showed them a card, or none at all.

Option 5: Display remaining unknown cards

Option 6: Display the room you should move to next.
This is based on cards without probability 1, and the closest room (based on old version of board layout).

Option 7: Display what is known about other players:
1.) Which cards the program for sure knows they have,
2.) Which cards the player could have at 50% or higher.

Option 8: Display General Tips.

Option 9: Quita the program and clears the database.

********************************************************************************/
/*
Dynamic predicates to represent suspected weapons, persons, and rooms
*/

% Room player is currently in (no room = corridor)
:- dynamic playerRoom/1.

/* List of all cards which have been shown or held up, shown cards are assigned prob of 100%
and eliminated from solution. An unknown card which is held up is assigned a probability
that the player has that card. shownCard(player,Card,probability) */
:- dynamic shownCard/3.

% Number of cards each player has.
:- dynamic numPlayerCards/1.

% Number of players in the game
:- dynamic numPlayers/1.

% holds the cards from opponent an guess
:- dynamic guessCards/1.

% Valid weapon check
isWeapon(knife).
isWeapon(candlestick).
isWeapon(revolver).
isWeapon(rope).
isWeapon(leadpipe).
isWeapon(wrench).

% Valid room check
isRoom(kitchen).
isRoom(ballroom).
isRoom(conservatory).
isRoom(billiardroom).
isRoom(library).
isRoom(study).
isRoom(hall).
isRoom(lounge).
isRoom(diningroom).

% Valid person check
isPerson(profplum).
isPerson(msscarlet).
isPerson(mrspeacock).
isPerson(revgreen).
isPerson(mrswhite).
isPerson(colmustard).

% Valid card check
isValidCard(Card) :- isWeapon(Card) ; isRoom(Card) ; isPerson(Card).

/**********************************************************************************/
% BEGIN GAMEPLAY PREDICATES 

% START program and enter play loop.
start :-
write('Welcome to the Clue Assistant program. ========='),nl,nl,
write('Enter the number of players: '),
read(Players),
assert(numPlayers(Players)),
write('Enter the number of cards you recieved: '),
read(Numcards),
assert(numPlayerCards(Numcards)),
entercards(1,Numcards),
playLoop.

% If the program prematurely quits, enter continue to get back to Options menu
continue :- showOptions.

% ENTERCARDS procedure to enter KNOWN cards (Player, Number of Cards to Enter)
entercards(_,0).
entercards(P,N) :-
N>0, % make sure positive number
write('Enter your first/next card: '),nl,
write('Reminder, the people for this program are: profplum, msscarlet, mrspeacock, revgreen, mrswhite, colmustard'),nl,
read(Card), 
isValidCard(Card),
assignAsserts(P,Card,1.0),
checkWin,
M is N-1,
entercards(P,M).

% PLAYLOOP for gameplay
playLoop :- showOptions.

% SHOWOPTIONS - MAIN MENU ===================
showOptions :-
nl,
write('MENU ------------------------------'),nl,
write('[1] for the current recommended move (guess)'),nl,
write('[2] to enter card discovered from your turn'),nl,
write('[3] to enter or leave a room'),nl,
write('[4] to enter an opponents guess'),nl,
write('[5] to show remaining possible cards'),nl,
write('[6] for the recommended room you should move to next'),nl,
write('[7] to show what is known about other players'),nl,
write('[8] for some general tips'),nl,
write('[9] quit program'),nl,
write(':'),
read(Option),
executeOption(Option).

% MIN Value Finder for evaluated numbers attached to Cards
min(X) :- isPerson(X),addProb(X,Z),not((isPerson(Y),addProb(Y,Other),Other<Z)),!.
min(X) :- isWeapon(X),addProb(X,Z),not((isWeapon(Y),addProb(Y,Other),Other<Z)),!.
min(X) :- isRoom(X),addProb(X,Z),not((isRoom(Y),addProb(Y,Other),Other<Z)),!.

% ADDPROB - HELPER for assignCards (card,Probability of player having)
addProb(X,Y) :- findall(P,shownCard(_,X,P),Z),addProbHelp(Z,SProb), Y is SProb.

% ADDPROBHELP - HELPER for addProb. Product of card probs HELPER
addProbHelp([],0).
addProbHelp([H|T],Sum) :-
addProbHelp(T,Sum1),
Sum is H + Sum1.

% HELPER for showOptions (MENU) executes selected option.

% EXECUTEOPTION[1] Gives the best guess based on the evaluator functions of the items in database
executeOption(1) :-
nl,
write('A good guess is: '),
% takes an unshown card or the lowest probability card
isPerson(X),(not(shownCard(_,X,_)) -> true ; min(X),not(shownCard(_,X,1.0))),
isWeapon(Y),(not(shownCard(_,Y,_)) -> true ; min(Y),not(shownCard(_,Y,1.0))),
isRoom(Z),(not(shownCard(_,Z,_)) -> true ; min(Z),not(shownCard(_,Z,1.0))),
write(X),
write(' with the '),
write(Y),
write(' in the '),
write(Z),
!, % cut so that it only gives one possible guess per execution.
nl,
showOptions.

% EXECUTEOPTION[2] Enters a card shown by an opponent
executeOption(2) :-
nl,
write('Which Player showed you the card (number)? '),
read(Player),
entercards(Player,1),
nl,
showOptions.

% EXECUTEOPTION[3] Tell the program you are entering or leaving a room
executeOption(3) :-
nl,
write('You are currently in the '),
%begin if-then-else
(playerRoom(X) -> write(X),
write('. Leave room [Y/N]? '),
read(Ans),
((Ans = 'Y' ; Ans = 'y') -> retract(playerRoom(_)) ; true) ;
write('corridor. Which room would you like to enter? '),
read(Room),
assert(playerRoom(Room))), % end if-then-else
showOptions.

% EXECUTEOPTION[4] Process a guess by an opponent
executeOption(4) :-
nl,
write('Which opponent made the guess (number)? '),
read(Opponent),
write('Enter the weapon they suggested: '),
read(SuggestedWeapon),
write('Enter the room they suggested: '),
read(SuggestedRoom),
write('Enter the person they suggested: '),nl,
write('Reminder, the people for this program are: profplum, msscarlet, mrspeacock, revgreen, mrswhite, colmustard'),nl,
read(SuggestedPerson),
write('Did anyone hold up a card to disprove? Enter the player (number) or [N] for none: '),
read(Player),
% if nobody disproved the cards, assume 15% chance the opponent is bluffing and has the card if the card
% is still in play.
% else assign the guessed cards w/ calculated probability to the player that defeated the guess
((Player = 'N' ; Player = 'n') ->
assignAsserts(Opponent,SuggestedPerson,0.15),
assignAsserts(Opponent,SuggestedWeapon,0.15),
assignAsserts(Opponent,SuggestedRoom,0.15) ;
opponentGuess([SuggestedPerson,SuggestedWeapon,SuggestedRoom],Player)),
checkWin,
showOptions.

% EXECUTEOPTION[5] Print to screen the remaining possible cards
executeOption(5) :- printAvailCards.

% EXECUTEOPTION[6] suggest best room to move to
executeOption(6) :- suggestRoom,showOptions.

% EXECUTEOPTION[7] Display stats of other players
executeOption(7) :-getOtherPlayerStats.

% EXECUTEOPTION[8] general playing tips
executeOption(8) :-
write('If you have the choice, when asked to show a card, try to keep showing the same card. Keep at least one of your cards hidden as long as possible.'),nl,
write('Reminder, the people for this program are: profplum, msscarlet, mrspeacock, revgreen, mrswhite, colmustard'),nl,
write('Always end you inputs with a full stop: . '),nl,
showOptions.

% EXECUTEOPTION[9] Clear database and exit program.
executeOption(9) :- clear.

% CLEAR - Retracts all dynamic elements
clear :- retractall(shownCard(_,_,_)), retractall(numPlayerCards(_)), retractall(numPlayers(_)), retractall(playerRoom(_)),retractall(guessCards(_)), false,halt.

% OPPONENTGUESS - HELPER for menu item [4] - assigns each card to dynamic guessCards, then runs sub HELPER
% assignCards which assigns the card to the opponent with a probability
opponentGuess([H|T],P) :-
assert(guessCards(H)),
opponentGuess(T,P).
opponentGuess([],P) :- assignCards(P),retractall(guessCards(_)),showOptions.


% ASSIGNCARDS - HELPER for opponentGuess -
/*
cards are held by other players with a percentage <= 1.0
each card (A,B,C) is assigned
30% * products(100%-percentage of card being held by others)i, i = 1...n
e.g. (1,knife,0.3),(2,knife,0.3) -> P(knife) for player 3  = P(knife)*(0.7*0.8) = P(knife)*0.56
the prob of p1 not having is 70% the prob of p2 not having is 80%. The prob of them BOTH
not having is .7*.8. And the prob of p3 is his probability of having P(knife) *
the probability that the other players DON'T have it. */

assignCards(P) :- guessCards(X),guessCards(Y),guessCards(Z),
X \= Y, Y \= Z, X \= Z, % assign guessCards to vars
assnProb(P,X,XP), assnProb(P,Y,YP), assnProb(P,Z,ZP),
assignAsserts(P,X,XP),
assignAsserts(P,Y,YP),
assignAsserts(P,Z,ZP).

%ASSIGNASSERTS - HELPER for assigncards handles assertions and retractions is player already
% has probability for the card.
assignAsserts(_,Card,_) :- shownCard(_,Card,1.0). % card is out of play, don't assign it.
assignAsserts(Player,Card,Prob) :- (not(shownCard(Player,Card,OP)) ->
((Prob >= 1.0) -> retractall(shownCard(_,Card,_)) ; true),assert(shownCard(Player,Card,Prob)) ;
shownCard(Player,Card,OP),X is OP + Prob,
((X >= 1.0) -> retractall(shownCard(_,Card,_)), % retractall other occurances and assert to 1.0
assert(shownCard(Player,Card,1.0)) ;
assert(shownCard(Player,Card,X)),retract(shownCard(Player,Card,OP)))).

% ASSNPROB - HELPER for assignCards (card,Probability of player having)
% Creates a list of all probabilities (not including players own existing prob)
% sends list to assnProbHelp for calculation
assnProb(Player,X,Y) :- findall(P,shownCard(_,X,P),Z),
remlist(Z,List,X,Player),
assnProbHelp(List,SProb), Y is 0.30*SProb.

% REMLIST - remove player's own entry from the list of probabilities (in,out,card,player)
remlist([],_,_,_).
remlist([H|T],X,Card,P) :- shownCard(P,Card,Prob),((H = Prob) -> append([],T,X) ;
remlist(T,K,Card,P),append([H],K,X)).
remlist(X,Y,Card,P) :- not(shownCard(P,Card,_)),append([],X,Y). % no entry for player, return full list

% ASSNPROBHELP - HELPER for addProb. Product of card probs HELPER
assnProbHelp([],1).
assnProbHelp([H|T],Sum) :-
assnProbHelp(T,Sum1),
H2 is 1 - H,
Sum is H2 * Sum1.

% PRINTAVAILCARDS - Lists all the cards that have not been shown yet
printAvailCards :- printSuspects ; printRooms ; printWeapons.
printAvailCards :- showOptions.

%PRINTSUSPECTS - HELPER for printAvailCards
printSuspects :-
nl,
write('Current Suspects: '),nl,nl,
isPerson(X),
not(shownCard(_,X,1.0)),
write(X),
nl,
fail.

%PRINTWEAPONS - HELPER for printAvailCards
printWeapons :-
nl,
write('Possible Weapons: '),nl,nl,
isWeapon(X),
not(shownCard(_,X,1.0)),
write(X),
nl,
fail.

%PRINTROOMS - HELPER for printAvailCards
printRooms :-
nl,
write('Possible Rooms: '),nl,nl,
isRoom(X),
not(shownCard(_,X,1.0)),
write(X),
nl,
fail.

/*
Check if the player knows enough to win,
A win is known if there is only 1 card in each category that is not a probability of 1
*/ 
checkWin :-
findall(X,(isWeapon(X),not(shownCard(_,X,1.0))),XL),
findall(Y,(isPerson(Y),not(shownCard(_,Y,1.0))),YL),
findall(Z,(isRoom(Z),not(shownCard(_,Z,1.0))),ZL),
length(XL,LengthX),
length(YL,LengthY),
length(ZL,LengthZ),
((LengthX > 1; LengthY > 1; LengthZ > 1) -> true;
nl,
write('The Answers are:'),nl,
write(XL),nl,
write(YL),nl,
write(ZL),nl).


% Function to suggest room user should move to next
suggestRoom :-
nl,
(playerRoom(X) -> Room = X;
write('What room are you in/nearest too?: '),nl,
read(Room)),nl,
write('What value did you roll?'),nl,
read(Value),nl,
minValidRoom(Room,Value,Y),!,
write('You should head to the: '),
write(Y),nl,!.

/*
 minValidRoom(Room,Value,X), Room is the room the player is in, Value is the result of the players dice/role.
 The function finds all the rooms the user can get to within the dice roll and returns the room with the lowest probability from that list, 
 if there are no rooms in that list that aren't already known,
 then the nearest room is given out of the rooms unknown
*/
minValidRoom(Room,Value,X) :-
findall(B,(steps(Room,B,Number),Number =< Value),Rooms),
findall(A,(shownCard(_,A,B),B<1.0),ProbableCards),
intersection(Rooms,ProbableCards,UsableRooms),
length(UsableRooms,NU),
(NU > 0 ->
(NU = 1 -> [X] = UsableRooms; getRooms(UsableRooms,Ans)),
min_in_list([Ans],Min),!,
shownCard(_,Answer,Min),
X = Answer
; 
findall(A1,(isRoom(A1),shownCard(_,A1,1.0)),Showncards1),
findall(B1,steps(Room,B1,_),Rooms1),
subtract(Rooms1,Showncards1,RemainingRooms1),
length(RemainingRooms1,N1),
(N1 = 1 -> X = RemainingRooms1;
getSteps(N1,Room,RemainingRooms1,Num1),
min_in_list([Num1],Min1),!,
steps(Room,Ans1,Min1),!,
X=Ans1)).

% Get a list of steps from input Room R to each room in list
getSteps(0,_,_,_).
getSteps(1,R,[RL],Num) :- steps(R,RL,Num),!.
getSteps(2,R,[R1,R2],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,Num=[A,B].
getSteps(3,R,[R1,R2,R3],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,Num=[A,B,C].
getSteps(4,R,[R1,R2,R3,R4],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,steps(R,R4,D),!,Num=[A,B,C,D].
getSteps(5,R,[R1,R2,R3,R4,R5],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,steps(R,R4,D),!,steps(R,R5,E),!,Num=[A,B,C,D,E].
getSteps(6,R,[R1,R2,R3,R4,R5,R6],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,steps(R,R4,D),!,steps(R,R5,E),!,steps(R,R6,F),!,Num=[A,B,C,D,E,F].
getSteps(7,R,[R1,R2,R3,R4,R5,R6,R7],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,steps(R,R4,D),!,steps(R,R5,E),!,steps(R,R6,F),!,steps(R,R7,G),!,Num=[A,B,C,D,E,F,G].
getSteps(8,R,[R1,R2,R3,R4,R5,R6,R7,R8],Num) :- steps(R,R1,A),!,steps(R,R2,B),!,steps(R,R3,C),!,steps(R,R4,D),!,steps(R,R5,E),!,steps(R,R6,F),!,steps(R,R7,G),!,steps(R,R8,H),!,Num=[A,B,C,D,E,F,G,H].

% Get a list of probabilities from the input list of rooms
getRooms([R1,R2],X) :- shownCard(_,R1,A),shownCard(_,R2,B),X=[A,B].
getRooms([R1,R2,R3],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),X=[A,B,C].
getRooms([R1,R2,R3,R4],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),shownCard(_,R4,D),X=[A,B,C,D].
getRooms([R1,R2,R3,R4,R5],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),shownCard(_,R4,D),shownCard(_,R5,E),X=[A,B,C,D,E].
getRooms([R1,R2,R3,R4,R5,R6],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),shownCard(_,R4,D),shownCard(_,R5,E),shownCard(_,R6,F),X=[A,B,C,D,E,F].
getRooms([R1,R2,R3,R4,R5,R6,R7],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),shownCard(_,R4,D),shownCard(_,R5,E),shownCard(_,R6,F),shownCard(_,R7,G),X=[A,B,C,D,E,F,G].
getRooms([R1,R2,R3,R4,R5,R6,R7,R8],X) :- shownCard(_,R1,A),shownCard(_,R2,B),shownCard(_,R3,C),shownCard(_,R4,D),shownCard(_,R5,E),shownCard(_,R6,F),shownCard(_,R7,G),shownCard(_,R8,H),X=[A,B,C,D,E,F,G,H].

% Returns Min, the minimum value in list
min_in_list([Min],Min).                 % We've found the minimum
min_in_list([H,K|T],M) :-
    H =< K,                             % H is less than or equal to K
    min_in_list([H|T],M).               % so use H

min_in_list([H,K|T],M) :-
    H > K,                              % H is greater than K
    min_in_list([K|T],M).               % so use K
 
% For each player, display their stats 
getOtherPlayerStats :-
numPlayers(X),
displayStats(X),
showOptions.

% Display the cards we know the player has, with probability 1,
% Display the cards we know the player could have with probability between 50% and 100%
displayStats(0).
displayStats(N) :-
N > 0,
findall(X,shownCard(N,X,1.0),KnownCards),
findall(Y,(shownCard(N,Y,Fifty),Fifty>0.5,Fifty<1.0),OverFiftyCards),
length(KnownCards,LenK),
length(OverFiftyCards,LenF),
(LenK > 0 -> nl,
write('Player: '),
write(N),
write(' definitely has these cards: '), nl,
write(KnownCards),nl
; true),
(LenF > 0 -> nl,
write('There is a 50% or greater chance that player: '),
write(N),
write(' has these cards: '), nl,
write(OverFiftyCards),nl
; true),
M is N-1,
displayStats(M).

% Steps(X,Y,Num): Num is Number of steps needed to get from X to Y 
% Assuming old board layout
/*
Hall	 
*/
steps(hall,study,4).
steps(hall,lounge,8).
steps(hall,library,7).
steps(hall,diningroom,8).
steps(hall,billiardroom,15).
steps(hall,conservatory,20).
steps(hall,ballroom,13).
steps(hall,kitchen,19).

/*
Study	 
*/
steps(study,hall,4).
steps(study,lounge,17).
steps(study,library,7).
steps(study,diningroom,17).
steps(study,billiardroom,15).
steps(study,conservatory,20).
steps(study,ballroom,17).
steps(study,kitchen,1).

/*
Lounge	 
*/
steps(lounge,hall,8).
steps(lounge,study,17).
steps(lounge,library,14).
steps(lounge,diningroom,4).
steps(lounge,billiardroom,22).
steps(lounge,conservatory,1).
steps(lounge,ballroom,15).
steps(lounge,kitchen,19).

/*
Library	 
*/
steps(library,hall,7).
steps(library,study,7).
steps(library,lounge,14).
steps(library,diningroom,14).
steps(library,billiardroom,4).
steps(library,conservatory,15).
steps(library,ballroom,12).
steps(library,kitchen,23).

/*
Dining Room	 
*/
steps(diningroom,hall,8).
steps(diningroom,study,17).
steps(diningroom,lounge,4).
steps(diningroom,library,14).
steps(diningroom,billiardroom,14).
steps(diningroom,conservatory,19).
steps(diningroom,ballroom,7).
steps(diningroom,kitchen,11).

/*
Billiard Room	 
*/
steps(billiardroom,hall,15).
steps(billiardroom,study,15).
steps(billiardroom,lounge,22).
steps(billiardroom,library,4).
steps(billiardroom,diningroom,14).
steps(billiardroom,conservatory,7).
steps(billiardroom,ballroom,6).
steps(billiardroom,kitchen,17).

/*
Conservatory	 
*/
steps(conservatory,hall,20).
steps(conservatory,study,20).
steps(conservatory,lounge,1).
steps(conservatory,library,15).
steps(conservatory,diningroom,19).
steps(conservatory,billiardroom,7).
steps(conservatory,ballroom,4).
steps(conservatory,kitchen,20).

/*
Ball Room	 
*/
steps(ballroom,hall,13).
steps(ballroom,study,17).
steps(ballroom,lounge,15).
steps(ballroom,library,12).
steps(ballroom,diningroom,7).
steps(ballroom,billiardroom,6).
steps(ballroom,conservatory,4).
steps(ballroom,kitchen,7).

/*
Kitchen	 
*/
steps(kitchen,hall,19).
steps(kitchen,study,1).
steps(kitchen,lounge,19).
steps(kitchen,library,23).
steps(kitchen,diningroom,11).
steps(kitchen,billiardroom,17).
steps(kitchen,conservatory,20).
steps(kitchen,ballroom,7).

