% تعريف حجم الرقعة
size(5).

% طباعة الرقعة
print_board(Size) :-
    print_row_separator(Size),
    print_rows(Size, 1),
    print_row_separator(Size).

print_rows(Size, Row) :-
    (Row > Size -> true ; print_row(Size, Row, 1), NextRow is Row + 1, print_rows(Size, NextRow)).

print_row(Size, Row, Col) :-
    (Col > Size -> write('|'), nl ; print_cell(Row, Col), NextCol is Col + 1, print_row(Size, Row, NextCol)).

print_cell(Row, Col) :-
    (write('|'),
     fixed_cell(Row, Col, Num) -> write('[ '), write(Num), write(' ]') ;
     (solve_cell(Row, Col, Color) -> write('['), write(Color), write(']') ;
     write('[   ]'))).


print_row_separator(Size) :-
    write_list('-', 4*Size), nl.

write_list(_, 0).
write_list(Item, N) :-
    write(Item),
    N1 is N - 1,
    write_list(Item, N1).

% خلية ثابتة
fixed_cell(1, 5, 1).
fixed_cell(1, 1, 4).
fixed_cell(3, 5, 2).
fixed_cell(5, 4, 1).

% حل الخلية
:- dynamic solve_cell/3.

% التحقق مما إذا كانت الخلية الزرقاء محاطة بخلايا خضراء من الجهات الأربع
is_blue_with_green_neighbors(Row, Col) :-
    solve_cell(Row, Col, blue),  % يجب أن تكون الخلية زرقاء
    RowUp is Row - 1, get_cell_color(RowUp, Col, green),  % الخلية فوقها خضراء
    RowDown is Row + 1, get_cell_color(RowDown, Col, green),  % الخلية تحتها خضراء
    ColLeft is Col - 1, get_cell_color(Row, ColLeft, green),  % الخلية على يسارها خضراء
    ColRight is Col + 1, get_cell_color(Row, ColRight, green).  % الخلية على يمينها خضراء

% تابع لإيجاد المجاورات للخلية ذات اللون نفسه بدون تمرير اللون كمعامل
get_neighbors(Row, Col, Neighbors) :-
    get_cell_color(Row, Col, Color),
    find_neighbors(Row, Col, Color, [], Neighbors).

% تابع مساعد لإيجاد المجاورات للخلية ذات اللون نفسه
find_neighbors(Row, Col, Color, Acc, Neighbors) :-                       
    findall([X, Y],
            (neighbor_position(Row, Col, X, Y),
             get_cell_color(X, Y, Color),
             \+ member([X, Y], Acc)),
            NewNeighbors),
    append(NewNeighbors, Acc, Neighbors).

% تابع للتحقق من لون الخلية الأصلية
get_cell_color(Row, Col, green) :-
    fixed_cell(Row, Col, _), !.
get_cell_color(Row, Col, Color) :-
    solve_cell(Row, Col, Color).

% تابع للتحقق من المواقع المجاورة الممكنة
neighbor_position(Row, Col, X, Y) :-
    (X is Row + 1, Y is Col);
    (X is Row - 1, Y is Col);
    (X is Row, Y is Col + 1);
    (X is Row, Y is Col - 1).

% تابع لإيجاد الخلايا المجاورة التي تشكل جزيرة من نفس اللون
get_island(Row, Col, Island) :-
    get_neighbors(Row, Col, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col]], Island).

% تابع للمساعدة في استكشاف الخلايا المجاورة
explore(Row, Col, Color, Visited, Island) :-
    member([Row, Col], Visited),
    !,
    Island = Visited.
explore(Row, Col, Color, Visited, Island) :-
    find_neighbors(Row, Col, Color, Visited, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col] | Visited], Island).

% تابع لاستكشاف جميع الخلايا المجاورة
explore_neighbors([], Island, Island).
explore_neighbors([[Row, Col] | Rest], Visited, Island) :-
    get_cell_color(Row, Col, Color),
    explore(Row, Col, Color, Visited, NewVisited),
    explore_neighbors(Rest, NewVisited, Island).

% تابع رئيسي لإيجاد الخلايا من نفس اللون المتجاورة أو جميع الخلايا الزرقاء
get_sea_or_island(Row, Col, Result) :-
    get_neighbors(Row, Col, Result).

% مسح الرقعة للتحقق من وجود أي خلية زرقاء محاطة بخلايا خضراء
find_blue_with_green_neighbors(Size, Row, Col) :-
    (Row > Size -> false  % إذا تجاوز الصف الحجم، انتهى المسح
    ; (Col > Size -> NextRow is Row + 1, find_blue_with_green_neighbors(Size, NextRow, 1)  % الانتقال للصف التالي
    ; (is_blue_with_green_neighbors(Row, Col) -> true  % إذا تم العثور على خلية تحقق الشرط، أعد true
    ; NextCol is Col + 1, find_blue_with_green_neighbors(Size, Row, NextCol)))).  % الانتقال للعمود التالي

% التابع الرئيسي للتحقق من وجود أي خلية زرقاء محاطة بخلايا خضراء
one_sea :-
    size(Size),  % تحديد حجم الرقعة
    find_blue_with_green_neighbors(Size, 1, 1).  % بدء المسح من الصف الأول والعمود الأول


% تابع للتحقق من أن كل جزيرة تحتوي على خلية ثابتة واحدة على الأكثر
one_fixed_cell_in_island :-
    size(Size),
    findall(Islands, (between(1, Size, Row), between(1, Size, Col), get_island(Row, Col, Islands)), AllIslands),
    remove_duplicates(AllIslands, UniqueIslands),
    forall(member(Island, UniqueIslands), valid_island(Island)).

% تابع للتاكد من ان قيمة الخلية الثابتة يساوي عدد عناصر جزيرتها
island_number_equals_size :-
    size(Size),
    forall((between(1, Size, Row), between(1, Size, Col), fixed_cell(Row, Col, Num)),
           (get_island(Row, Col, Island),
            list_length(Island, Length),
            Length == Num)).

% إزالة الجزر المتكررة
remove_duplicates([], []).
remove_duplicates([H|T], Result) :-
    member(H, T),
    !,
    remove_duplicates(T, Result).
remove_duplicates([H|T], [H|Result]) :-
    remove_duplicates(T, Result).

% التحقق من أن الجزيرة تحتوي على خلية ثابتة واحدة على الأكثر
valid_island(Island) :-
    findall(Cell, (member([Row, Col], Island), fixed_cell(Row, Col, Cell)), FixedCells),
    length(FixedCells, Length),
    Length =< 1.

no_four_blue_cells_adjacent :-
    \+ (between(1, 4, Row),
        between(1, 4, Col),
        check_square_2x2(Row, Col)).

% تابع للتحقق من المربع 2x2 بدءاً من الخلية في (Row, Col)
check_square_2x2(Row, Col) :-
    R1 is Row + 1,
    C1 is Col + 1,
    solve_cell(Row, Col, blue),
    solve_cell(Row, C1, blue),
    solve_cell(R1, Col, blue),
    solve_cell(R1, C1, blue).


% طباعة الرقعة
print_board(Size) :-
    print_row_separator(Size),
    print_rows(Size, 1),
    print_row_separator(Size).

print_rows(Size, Row) :-
    (Row > Size -> true ; print_row(Size, Row, 1), NextRow is Row + 1, print_rows(Size, NextRow)).

print_row(Size, Row, Col) :-
    (Col > Size -> write('|'), nl ; print_cell(Row, Col), NextCol is Col + 1, print_row(Size, Row, NextCol)).

print_cell(Row, Col) :-
    (write('|'),
     fixed_cell(Row, Col, Num) -> write('[ '), write(Num), write(' ]') ;
     (solve_cell(Row, Col, Color) -> write('['), write(Color), write(']') ;
     write('[   ]'))).

print_row_separator(Size) :-
    write_list('-', 4*Size), nl.

write_list(_, 0).
write_list(Item, N) :-
    write(Item),
    N1 is N - 1,
    write_list(Item, N1).

% خلية ثابتة
fixed_cell(1, 5, 1).
fixed_cell(2, 3, 4).
fixed_cell(3, 5, 2).
fixed_cell(5, 4, 1).
fixed_cell(3, 2, 2).


% حل الخلية
:- dynamic solve_cell/3.

% التحقق مما إذا كانت الخلية الزرقاء محاطة بخلايا خضراء من الجهات الأربع
is_blue_with_green_neighbors(Row, Col) :-
    solve_cell(Row, Col, blue),  % يجب أن تكون الخلية زرقاء
    RowUp is Row - 1, get_cell_color(RowUp, Col, green),  % الخلية فوقها خضراء
    RowDown is Row + 1, get_cell_color(RowDown, Col, green),  % الخلية تحتها خضراء
    ColLeft is Col - 1, get_cell_color(Row, ColLeft, green),  % الخلية على يسارها خضراء
    ColRight is Col + 1, get_cell_color(Row, ColRight, green).  % الخلية على يمينها خضراء

% تابع لإيجاد المجاورات للخلية ذات اللون نفسه بدون تمرير اللون كمعامل
get_neighbors(Row, Col, Neighbors) :-
    get_cell_color(Row, Col, Color),
    find_neighbors(Row, Col, Color, [], Neighbors).


% تابع مساعد لإيجاد المجاورات للخلية ذات اللون نفسه
find_neighbors(Row, Col, Color, Acc, Neighbors) :-
    findall([X, Y],
            (neighbor_position(Row, Col, X, Y),
             get_cell_color(X, Y, Color),
             \+ member([X, Y], Acc)),
            NewNeighbors),
    append(NewNeighbors, Acc, Neighbors).

% تابع للتحقق من لون الخلية الأصلية
get_cell_color(Row, Col, green) :-
    fixed_cell(Row, Col, _), !.
get_cell_color(Row, Col, Color) :-
    solve_cell(Row, Col, Color).

% تابع للتحقق من المواقع المجاورة الممكنة
neighbor_position(Row, Col, X, Y) :-
    (X is Row + 1, Y is Col);
    (X is Row - 1, Y is Col);
    (X is Row, Y is Col + 1);
    (X is Row, Y is Col - 1).

% تابع لإيجاد الخلايا المجاورة التي تشكل جزيرة من نفس اللون
get_island(Row, Col, Island) :-
    get_neighbors(Row, Col, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col]], Island).

% تابع للمساعدة في استكشاف الخلايا المجاورة
explore(Row, Col, Color, Visited, Island) :-
    member([Row, Col], Visited),
    !,
    Island = Visited.
explore(Row, Col, Color, Visited, Island) :-
    find_neighbors(Row, Col, Color, Visited, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col] | Visited], Island).

% تابع لاستكشاف جميع الخلايا المجاورة
explore_neighbors([], Island, Island).
explore_neighbors([[Row, Col] | Rest], Visited, Island) :-
    get_cell_color(Row, Col, Color),
    explore(Row, Col, Color, Visited, NewVisited),
    explore_neighbors(Rest, NewVisited, Island).

% تابع رئيسي لإيجاد الخلايا من نفس اللون المتجاورة أو جميع الخلايا الزرقاء
get_sea_or_island(Row, Col, Result) :-
    get_neighbors(Row, Col, Result).

% مسح الرقعة للتحقق من وجود أي خلية زرقاء محاطة بخلايا خضراء
find_blue_with_green_neighbors(Size, Row, Col) :-
    (Row > Size -> false  % إذا تجاوز الصف الحجم، انتهى المسح
    ; (Col > Size -> NextRow is Row + 1, find_blue_with_green_neighbors(Size, NextRow, 1)  % الانتقال للصف التالي
    ; (is_blue_with_green_neighbors(Row, Col) -> true  % إذا تم العثور على خلية تحقق الشرط، أعد true
    ; NextCol is Col + 1, find_blue_with_green_neighbors(Size, Row, NextCol)))).  % الانتقال للعمود التالي

% التابع الرئيسي للتحقق من وجود أي خلية زرقاء محاطة بخلايا خضراء
one_sea :-
    size(Size),  % تحديد حجم الرقعة
    find_blue_with_green_neighbors(Size, 1, 1).  % بدء المسح من الصف الأول والعمود الأول


% تابع للتحقق من أن كل جزيرة تحتوي على خلية ثابتة واحدة على الأكثر
one_fixed_cell_in_island :-
    size(Size),
    findall(Islands, (between(1, Size, Row), between(1, Size, Col), get_island(Row, Col, Islands)), AllIslands),
    remove_duplicates(AllIslands, UniqueIslands),
    forall(member(Island, UniqueIslands), valid_island(Island)).

% تابع للتاكد من ان قيمة الخلية الثابتة يساوي عدد عناصر جزيرتها
island_number_equals_size :-
    size(Size),
    forall((between(1, Size, Row), between(1, Size, Col), fixed_cell(Row, Col, Num)),
           (get_island(Row, Col, Island),
            list_length(Island, Length),
            Length == Num)).

% إزالة الجزر المتكررة
remove_duplicates([], []).
remove_duplicates([H|T], Result) :-
    member(H, T),
    !,
    remove_duplicates(T, Result).
remove_duplicates([H|T], [H|Result]) :-
    remove_duplicates(T, Result).

% التحقق من أن الجزيرة تحتوي على خلية ثابتة واحدة على الأكثر
valid_island(Island) :-
    findall(Cell, (member([Row, Col], Island), fixed_cell(Row, Col, Cell)), FixedCells),
    length(FixedCells, Length),
    Length =< 1.

no_four_blue_cells_adjacent :-
    \+ (between(1, 4, Row),
        between(1, 4, Col),
        check_square_2x2(Row, Col)).

% تابع للتحقق من المربع 2x2 بدءاً من الخلية في (Row, Col)
check_square_2x2(Row, Col) :-
    R1 is Row + 1,
    C1 is Col + 1,
    solve_cell(Row, Col, blue),
    solve_cell(Row, C1, blue),
    solve_cell(R1, Col, blue),
    solve_cell(R1, C1, blue).

% الشروط الأخرى لضمان الحل الصحيح
solve :-
    one_fixed_cell_in_island,
    \+ one_sea,
    island_number_equals_size,
    no_four_blue_cells_adjacent.



% التحقق من الجوار القطري وإضافة خلايا زرقاء
diagonally_adjacent_clues :-
    size(Size),
   ( between(1, Size, Row),
    between(1, Size, Col),
    (   (Row1 is Row - 1, Col1 is Col - 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   (Row1 is Row - 1, Col1 is Col + 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)), Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row + 1, Col1 is Col - 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   (Row1 is Row + 1, Col1 is Col + 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),

    fail;  % لضمان التكرار على كل القيم الممكن
    true, % لاستكمال التنفيذ بعد انتهاء التكرار
print_board(5)).






clues_separated_by_one_square :-
    size(Size),
   (    between(1, Size, Row),
    between(1, Size, Col),
    (   (Col1 is Col - 2, fixed_cell(Row, Col, _), fixed_cell(Row, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row - 2, fixed_cell(Row, Col, _), fixed_cell(Row1, Col, _)) ->
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   ( Col1 is Col+2, fixed_cell(Row, Col, _), fixed_cell(Row, Col1, _)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row + 2, fixed_cell(Row, Col, _), fixed_cell(Row1, Col, _)) ->
        (Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),

    fail;  % لضمان التكرار على كل القيم الممكن
    true,  % لاستكمال التنفيذ بعد انتهاء التكرار
print_board(5)).




island_of_1 :-retractall(solve_cell(_,_,_)),
    size(Size),
    between(1, Size, Row),
    between(1, Size, Col),
    (   ( fixed_cell(Row, Col, 1)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue))),
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
    true
    ),


    fail;  % لضمان التكرار على كل القيم الممكن
    true.  % لاستكمال التنفيذ بعد انتهاء التكرار

island_of_11 :-  size(Size),
    between(1, Size, Row),
    between(1, Size, Col),
    (   ( fixed_cell(Row, Col, 1)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue))),
        (Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
    true
    ),


    fail;  % لضمان التكرار على كل القيم الممكن
    true.  % لاستكمال التنفيذ بعد انتهاء التكرار



% تحديث الخلايا المحلولة - ديناميكي
update_solved_cells :-
   island_of_1 ,
   island_of_11.

% طباعة الرقعة بعد التحديث
print_updated_board :-
    update_solved_cells,
    print_board(5).

% التابع الرئيسي لاستدعاء تحديث الخلايا وطباعة الرقعة
run :-
    print_updated_board.













