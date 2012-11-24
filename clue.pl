/*
Dynamic predicates to represent suspected weapons, persons, and rooms
*/

% Current Suspects suspect(id,eval)
:- dynamic suspect/2.

% Current Possible Weapons mweapon(id,eval)
:- dynamic mweapon/2.

% Current Possible Rooms mroom(id,eval)
:- dynamic mroom/2.

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

% holds the valid cards from opponent an guess
% guessCards(ID,0 = unowned card,1 = owned by THIS opponent)
:- dynamic guessCards/2.

% SOLUTION predicate
%murderer(X) :- suspect(),weapon(),room()

/*
Build predicate to take in game init: num players, who starts, cards given
*/

notWeapon(X) :- not(isWeapon(X)).
notRoom(X) :- not(isRoom(X)).
notValidPerson(X) :- not(isPerson(X)).

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

% builddynamics takes all possible items and creates a dynamic game w/ eval arrity
builddynamics :- buildSuspects.
builddynamics :- buildWeapons.
builddynamics :- buildRooms.
builddynamics.

buildSuspects :- isPerson(X),assert(suspect(X,0)),fail.
buildWeapons :- isWeapon(Y),assert(mweapon(Y,0)),fail.
buildRooms :- isRoom(Z),assert(mroom(Z,0)),fail.

% BEGIN GAMEPLAY PREDICATES ---------------------

% START program and enter play loop.
start :-
builddynamics,
write('Welcome to the Clue Assistant program. ========='),nl,nl,
write('Enter the number of players: '),
read(Players),
assert(numPlayers(Players)),
write('Enter the number of cards you recieved: '),
read(Numcards),
assert(numPlayerCards(Numcards)),
entercards(1,Numcards),
playLoop.

% ENTERCARDS procedure to enter KNOWN cards (Player, Number of Cards to Enter)
entercards(_,0).
entercards(P,N) :-
N>0, % make sure positive number
write('Enter your first/next card: '),
read(Card),
isValidCard(Card),
assert(shownCard(P,Card,100)),
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
write('[6] quit program'),nl,
write(':'),
read(Option),
executeOption(Option).

% MIN Value Finder for evaluated numbers attached to Cards
min(X) :- suspect(X,Z),not((suspect(X,Other),Other<Z)),!.
min(X) :- mweapon(X,Z),not((mweapon(X,Other),Other<Z)),!.
min(X) :- mroom(X,Z),not((mroom(X,Other),Other<Z)),!.

% HELPER for showOptions (MENU) executes selected option.

% EXECUTEOPTION[1] Gives the best guess based on the evaluator functions of the items in database
executeOption(1) :-
nl,
write('A good guess is: '),
suspect(X,_),min(X),not(shownCard(_,X,_)),
mweapon(Y,_),min(Y),not(shownCard(_,Y,_)),
mroom(Z,_),min(Z),not(shownCard(_,Z,_)),
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
read(Player),
write('Enter your opponents guess in the form [person,weapon,room] : '),
read(GuessArray),
opponentGuess(GuessArray,Player),
showOptions.

% EXECUTEOPTION[5] Print to screen the remaining possible cards
executeOption(5) :- printAvailCards.

% EXECUTEOPTION[6] Clear database and exit program.
executeOption(6) :- clear.

% CLEAR - Retracts all dynamic elements
clear :- retractall(shownCard(_,_,_)), retractall(numPlayerCards(_)), retractall(numPlayers(_)), retractall(playerRoom(_)),
    retractall(suspect(_,_)), retractall(mweapon(_,_)),
    retractall(mroom(_,_)),retractall(guessCards(_)), false.

% OPPONENTGUESS - HELPER for menu item [4] - assigns each card to dynamic guessCards, then runs sub HELPER
% assignCards which assigns the card to the opponent with a probability
opponentGuess([H|T],P) :-
(not(shownCard(_,H,100)) -> assert(guessCards(H,0)) ; true),
((shownCard(P,H,100)) -> assert(guessCards(H,1)) ; true),
opponentGuess(T,P).
opponentGuess([],P) :- assignCards(P), showOptions.


% ASSIGNCARDS - HELPER for opponentGuess -

%case 1: no other opponent has any of the three cards
%ALL three possible cards are added with a probabilty of 30

assignCards(P) :- guessCards(X,0),guessCards(Y,0),guessCards(Z,0),
X \= Y, Y \= Z, X \= Z,
assert(shownCard(P,X,30)),assert(shownCard(P,Y,30)),assert(shownCard(P,Z,30)),!.

%case 2: one of the cards is held by an opponent != P w/ prob 100
%two unheld cards are added with a probability of 50

assignCards(P) :- guessCards(X,0),guessCards(Y,0),
X \= Y,
assert(shownCard(P,X,50)),assert(shownCard(P,Y,50)),!.

%case 2b: one of the cards is held by this opponent == P w/ prob 100

assignCards(P) :- guessCards(X,0),guessCards(Y,0),guessCards(Z,1),
X \= Y, Y \= Z, X \= Z,
assert(shownCard(P,X,30)),assert(shownCard(P,Y,30)),!.

%case 3: two of the cards are held by opponent != P w/ prob 100
%unheld card is added to player w/ prob 100

assignCards(P) :- guessCards(X),
assert(shownCard(P,X,100)),!.

%case 3b: two of the cards are held by this opponent == P w/ prob 100

assignCards(P) :- guessCards(X,0),guessCards(Y,1),guessCards(Z,1),
X \= Y, Y \= Z, X \= Z,
assert(shownCard(P,X,30)),!.

%case 4: cards are held by other players with a percentage < 100
%each card (A,B,C) is assigned 30% * (100%-percentage of card being held by others)


assignCards(_).


% ADDER - ads two values together
adder(X,Y,Z) :- Z is X+Y.

% INCR - number incrementer
incr(X,X1) :- X1 is X+1.

% PRINTAVAILCARDS - Lists all the cards that have not been shown yet
printAvailCards :- printSuspects ; printRooms ; printWeapons.
printAvailCards :- showOptions.

%PRINTSUSPECTS - HELPER for printAvailCards
printSuspects :-
nl,
write('Current Suspects: '),nl,nl,
suspect(X,_),
not(shownCard(_,X,100)),
write(X),
nl,
fail.

%PRINTWEAPONS - HELPER for printAvailCards
printWeapons :-
nl,
write('Possible Weapons: '),nl,nl,
mweapon(X,_),
not(shownCard(_,X,100)),
write(X),
nl,
fail.

%PRINTROOMS - HELPER for printAvailCards
printRooms :-
nl,
write('Possible Rooms: '),nl,nl,
mroom(X,_),
not(shownCard(_,X,100)),
write(X),
nl,
fail.


/* NOTES and ideas

1. Anthony

make a dynamic predicate called
opponentsCards(player,card,probability)

ADD all YOUR cards with prob 100

when a player shows YOU a card during your turn it is added with probability of 100

when a player holds up a card to beat the guess of another player

case 1: no other opponent has any of the three cards
ALL three possible cards are added with a probabilty of 30

case 2: one of the cards is held by another opponent w/ prob 100
two unheld cards are added with a probability of 50

case 3: two of the cards are held by opponents w/ prob 100
unheld card is added to player w/ prob 100

case 4: cards are held by other players with a percentage < 100
each card (A,B,C) is assigned 30% * (100%-percentage of card being held by others)




2. Jessyka

Keep track of room distances from player

when you enter a room all the room values should also change based on the absolute distance from the room you are currently in. so say you have room(kitchen,1) room(study,0) room(library,2) then you go into the library… it becomes: room(library,2) room(study,1) room(kitchen,4)

*/

