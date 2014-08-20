


                   ;;;;;COMPUTER MODELS OF MUSICAL CREATIVITY;;;;;
                   ;;;;;            By David Cope            ;;;;;
                   ;;;;;     Improvise Function/Chapter 4    ;;;;;
                   ;;;;;             COMMON LISP             ;;;;;
                   ;;;;;     simple code to run Improvise    ;;;;;
                   ;;;;;               function              ;;;;;
                   ;;;;;COMPUTER MODELS OF MUSICAL CREATIVITY;;;;;

;========================
;some global and general variable declarations
;========================

(defVar *NEW-WORK* () "Storage for the new work in events.")
(defVar *THE-LAST-FIRST-CHOICE* () "Variable to avoid choosing the same first choice grouping each time.")
(defVar *DATABASE-NAMES* () "Place to store the lexicon names.")
(defVar *LEXICONS* () "Storing the lexicon names.")
(defVar *GROUPINGS* () "A place to store the un-named grouped events.")
(defVar SEED 1 "The seed number for naming groupings.")
(defVar *GROUPING-NAMES* () "For storing grouping names.")
(defVar *FIRST-GROUPINGS* () "location of all of the first grouping names in order")
(defVar TEST () "For use in system profile.")
(defVar DESTINATION-NAME () "Same as above but offset.")
(defVar NAME () "To temporarily store destination names.")
(defVar TIED-EVENTS () "Part of the test for re-tying events.")
(defVar *SAVE-GROUPINGS* () "Saving the groupings for inspection and other uses.")
(setq *channel-1* 1 *channel-2* 1 *channel-3* 1 *channel-4* 1 *channel-5* 1 *channel-6* 1
*channel-7* 1 *channel-8* 1 *channel-9* 1 *channel-10* 1 *channel-11* 1 *channel-12* 1
*channel-13* 1 *channel-14* 1 *channel-15* 1 *channel-16* 1)

;========================
;the principal improvising top-level functions
;========================

;;;;;
#| Calling (improvise (forgray)) 
   improvise returned ((0 46 292 1 97) (0 55 292 1 101) (0 60 292 1 98)
                     (0 50 292 1 90) (292 45 708 1 97) . . . |#
;;;;;

(defun IMPROVISE (databases)
  "This fcn creates a new database if necessary (i.e., new names in its arg) and runs improvise-it."
  (if (all-equal databases *database-names*)
    (improvise-it)
    (progn (create-a-complete-database databases)
           (improvise-it))))

;;;;;
#| Calling (all-equal (forgray) (forgray)) 
   all-equal returned t|#
;;;;;

(defun ALL-EQUAL (set-1 set-2)
  "This function voids the need to rebuild the database when improvise is called with the same names."
  (cond ((and (null set-1)(null set-2)) t)
        ((member (first set-1) set-2 :test #'equal)
         (all-equal (rest set-1)(remove (first set-1) set-2)))
        (t ())))

;;;;;
#| Calling (improvise-it) 
    improvise-it returned ((0 92 500 1 103) (0 48 1000 1 90)
                        (292 57 2208 1 94) . . . |#
;;;;;

(defun IMPROVISE-IT ()
  "Recombines the groupings, applies a new overall duration set, and makes the data playable."
  (setq *new-work*
        (reduce-ties (make-playable 
                      (let* ((chosen-grouping 
                              (choose-a-random-start-grouping *lexicons*))
                             (next-choice (destination (eval chosen-grouping))))
                        (if (equal next-choice 'end) (list chosen-grouping)
                            (cons chosen-grouping (sequence-through-groupings next-choice))))))))

;========================
;collecting the groupings
;========================

;;;;;
#| (collect-groupings 1 forgray)
(((2500 2792) ((2500 77 292 1 127 TIE) (2500 36 292 1 88 TIE))) ((2792 3000) 
((2792 77 20 1 127) (2792 36 182 1 88) (2792 74 208 1 84 TIE))) . . . .|#
;;;;;

(defun COLLECT-GROUPINGS (events &optional (cut 0))
  "Top level function to collect groupings from the database."
  (if (null (find-next-new-ontime events))(list (list (list cut (+ (very-first events)(third (first events)))) events))
      (let* ((cutoff-time (find-next-new-ontime events))
             (grouping (get-all-simultaneous-attacks events))
             (clipped-grouping (clip cutoff-time grouping)))
        (cons (list (list (very-first events) cutoff-time) clipped-grouping)
              (collect-groupings (append (remainder cutoff-time grouping)
                                         (remove-all grouping events))
                                 cutoff-time)))))

;;;;;
#| (find-next-new-ontime
           ((7000 55 156 1 94) (7000 60 156 1 94) (7000 50 156 1 89)
            (7000 46 489 1 97) (7312 55 99 1 101) (7312 60 114 1 98)
            (7312 50 109 1 90) (7500 45 489 1 97) (7792 77 234 1 95)
            (8000 74 344 1 82) (8000 46 323 1 97) (8333 45 156 1 95) . . .
   find-next-new-ontime returned 7312|#
;;;;;

(defun FIND-NEXT-NEW-ONTIME (events &optional (time (very-first events)))
  "Finds the next new ontime past the onset events."
  (cond ((null events)())
        ((> (very-first events) time) (very-first events))
        (t (find-next-new-ontime (rest events) time))))

;;;;;
#| Calling (get-all-simultaneous-attacks
           ((7000 55 156 1 94) (7000 60 156 1 94) (7000 50 156 1 89)
            (7000 46 489 1 97) . . .
   get-all-simultaneous-attacks returned ((7000 55 156 1 94)
                                        (7000 60 156 1 94)
                                        (7000 50 156 1 89)
                                        (7000 46 489 1 97))|#
;;;;;

(defun GET-ALL-SIMULTANEOUS-ATTACKS (events &optional (time (very-first events)))
  "Returns all of the events with the same initial ontime at the nead of events."
  (if (or (null events)(not (equal time (very-first events)))) ()
      (cons (first events)
            (get-all-simultaneous-attacks (rest events) time))))

;;;;;
#| Calling (clip 7312
               ((7000 55 156 1 94) (7000 60 156 1 94) (7000 50 156 1 89)
                (7000 46 489 1 97))) 
 clip returned ((7000 55 156 1 94) (7000 60 156 1 94) (7000 50 156 1 89)
                (7000 46 312 1 97 tie))|#
;;;;;

(defun CLIP (cutoff-time grouping)
  "Clips the endings off of events which extend beyond the entrance of a new event."
  (cond ((or (null cutoff-time)(null grouping))())
        ((<= (+ (very-first grouping)(third (first grouping))) cutoff-time)
         (cons (first grouping)
               (clip cutoff-time (rest grouping))))
        (t (cons (append (firstn 2 (first grouping))
                         (list (- cutoff-time (very-first grouping)))
                         (nthcdr 3 (first grouping))
                         (list 'tie))
                 (clip cutoff-time (rest grouping))))))

;;;;;
#| Calling (remainder 7312
                    ((7000 55 156 1 94) (7000 60 156 1 94)
                     (7000 50 156 1 89) (7000 46 489 1 97))) 
    remainder returned ((7312 46 177 1 97))|#
;;;;;

(defun REMAINDER (cutoff-time grouping)
  "Returns the remainder of the events which extend beyond the entrance of a new event."
  (cond ((null grouping)())
        ((<= (+ (very-first grouping)(third (first grouping))) cutoff-time)
         (remainder cutoff-time (rest grouping)))
        (t (cons (append (list cutoff-time)
                         (list (second (first grouping)))
                         (list (- (third (first grouping))(- cutoff-time (very-first grouping))))
                         (nthcdr 3 (first grouping)))
                 (remainder cutoff-time (rest grouping))))))
      

;========================
;the basic objects for the data
;========================

;;;;;
#| (make-instance 'lexicon)
    #<lexicon #x2704B8E>|#
;;;;;

(defClass LEXICON ()
  ((grouping-names :initarg :grouping-names :initform nil :accessor grouping-names)
   (last-choice :initarg :last-choice :initform nil :accessor last-choice))
  (:documentation "The top-level object which stores grouping names."))

(defClass GROUPING ()
  ((name :initarg :name :initform nil :accessor name)
   (timing :initarg :timing :initform nil :accessor timing)
   (destination :initarg :destination :initform nil :accessor destination)
   (events :initarg :events :initform nil :accessor events)
   (lexicon :initarg :lexicon :initform nil :accessor lexicon))
  (:documentation "The object for storing groupings."))

;========================
;putting the data into the objects
;========================

;;;;;
#| Calling (create-a-complete-database (fourbros)) 
     create-a-complete-database returned t|#
;;;;;

(defun CREATE-A-COMPLETE-DATABASE (names-of-eventlists)
  "Top-level of the database creating program."
  (setq  *database-names* (remove-duplicates (append names-of-eventlists *database-names*)))
  (loop for event-list-name in names-of-eventlists
        do (create-database-and-put-into-lexicons event-list-name (eval event-list-name)))
  t)

;;;;;
#| Calling (create-database-and-put-into-lexicons
            fourbros
            ((2000 65 354 1 92) (2000 72 375 1 92) (2000 51 62 1 90) . . .
   create-database-and-put-into-lexicons returned (lexicon-77-36 lexicon-77-36-74
                                                  lexicon-74-70-34 lexicon-70-36 . . .|#
;;;;;

(defun CREATE-DATABASE-AND-PUT-INTO-LEXICONS (source events)
  "Pujts the various data into each object and then the object itself into the proper lexicon."
   (setq *groupings* (collect-groupings events))
   (create-database source)
   (loop for grouping in *grouping-names*
         do (let ((lexicon-name (make-name-of-lexicon (mapcar #'second (events (eval grouping))))))
              (if (boundp lexicon-name)
                (progn
                  (setf (grouping-names (eval lexicon-name))
                        (cons grouping (grouping-names (eval lexicon-name))))
                  (setf (lexicon (eval grouping)) lexicon-name))
                (progn (set lexicon-name
                            (make-instance 'lexicon :grouping-names (list grouping)))
                       (setf (lexicon (eval grouping)) lexicon-name)
                       (setq *lexicons* (append *lexicons* (list lexicon-name)))))))
   *lexicons*)

;;;;;
#| Calling (create-database fourbros) 
    create-database returned (fourbros[81]-65-72-51
                             fourbros[82]-65-72-51-68-35
                             fourbros[83]-65-72-51-68-35-49 . . .|#
;;;;;

(defun CREATE-DATABASE (source &optional (beginning t))
  "The low-level function for creating instances of grouping objects."
   (setq *grouping-names* ())
   (setq destination-name ())
   (let ((groupings *groupings*))
     (loop until (null groupings)
           do (setq test groupings)
           do (setq name (make-name-of-object source (mapcar #'second (second (first groupings)))))
           do (setq destination-name (if (null (second groupings)) 'end
                                         (make-new-name-of-object source (mapcar #'second (second (second groupings))))))
           collect (set name
                        (make-instance 'grouping 
                          :name source
                          :timing (first (first groupings))
                          :destination destination-name
                          :events (second (first groupings))))
           do (setq *grouping-names* (append *grouping-names* (list name)))
           do (if beginning (progn (setf *first-groupings* (append *first-groupings* (list name)))
                                   (setf beginning ())))
           do (setq groupings (rest groupings))))
   *grouping-names*)

;========================
;naming the objects
;========================

;;;;;
#| Calling (make-name-of-lexicon (63 59 37)) 
    make-name-of-lexicon returned lexicon-63-59-37|#
;;;;;

(defun MAKE-NAME-OF-LEXICON (pitches)
        " Calling (make-name-of-lexicon (0)) 
            make-name-of-lexicon returned lexicon-[1]-0
           where the bracketed number is the order."
  (implode (append '(lexicon-) (interspace-hyphens pitches))))

;;;;;
#|  Calling (make-name-of-object improv (68)) 
     make-name-of-object returned improv[383]-68|#
;;;;;

(defun MAKE-NAME-OF-OBJECT (name pitches)
  "Makes names for objects."
  (implode (append  (list name '[ (incf seed) '] '-)
                   (interspace-hyphens pitches))))

;;;;;
#| Calling (make-new-name-of-object improv (43 53 71)) 
    make-new-name-of-object returned improv[411]-43-53-71|#
;;;;;

(defun MAKE-NEW-NAME-OF-OBJECT (name pitches)
  "Creates the names of objects that follow other objects."
  (implode (append (list name '[ (1+ seed) '] '-)  (interspace-hyphens pitches))))

;;;;;
#| Calling (interspace-hyphens (68 70)) 
   interspace-hyphens returned (68 - 70)|#
;;;;;

(defun INTERSPACE-HYPHENS (list)
  "Places hyphens between the various symbols in its lits arg."
  (if (null (rest list)) list
      (append (list (first list) '-)
              (interspace-hyphens (rest list)))))

;========================
;cleaning up
;========================

;;;;;
#| (remove-data)
     ()|#
;;;;;

(defun REMOVE-DATA ()
  "Cleans up databases for starting over."
  (setq *first-groupings* ())
  (mapcar #'makunbound *lexicons*)  
  (setq *lexicons* ())
  (mapcar #'makunbound *grouping-names*)
  (setq *grouping-names* ())
  (setq *groupings* ())
  (setq *save-groupings* ())
  (setq *database-names* ())
  (setq test ())
  (setq name ()))

;========================
;initiating a new improvisation
;========================

;;;;;
#| (choose-a-random-start-grouping
           (lexicon-77-36 lexicon-77-36-74 . . .
     choose-a-random-start-grouping returned fourbros[110]-62-65-68-44-41-51|#
;;;;;

(defun CHOOSE-A-RANDOM-START-GROUPING (lexicons)
  "Returns a randomly chosen object for begining a recombination."
  (setq *the-last-first-choice* 
        (choose-beginning-grouping
         (grouping-names (eval (choose (remove-ends lexicons)))))))

;;;;;
#|  Calling (choose-beginning-grouping (fourbros[110]-62-65-68-44-41-51)) 
  choose-beginning-grouping returned fourbros[110]-62-65-68-44-41-51|#
;;;;;

(defun CHOOSE-BEGINNING-GROUPING (list)
  "Chooses randomly from its list arg but avoids the end and rests."
  (let ((test (nth (random (length list) *rs*)
                   list)))
    (cond ((null (rest list)) (first list))
          ((and 
            (not (equal (destination (eval test)) 'end))
            (not (zerop (get-first-pitch (events (eval test)))))
            (not (equal test (last-choice (eval (lexicon (eval test))))))
            (and (> (length list) 1)(not (equal *the-last-first-choice* test))))
           test)
          (t (choose-beginning-grouping list)))))

;;;;;
#| Calling (choose (1 2 3 4)) 
    choose returned 3|#
;;;;;

(defun CHOOSE (list)
        "Chooses randomly from its list arg."
  (nth (random (length list) *rs*)
                   list))

;========================
;functions to promote diversity
;========================

;;;;;
#|  Calling (remove-ends (lexicon-77-36 lexicon-77-36-74 lexicon-74-70-34 . . . 
    remove-ends returned (lexicon-77-36 lexicon-77-36-74 lexicon-74-70-34
                       lexicon-70-36 lexicon-70-38 lexicon-70-39 . . .|#
;;;;;

(defun REMOVE-ENDS (lexicons)
  "Removes lexicons that contain only final groupings."
  (cond ((null lexicons)())
        ((check-for-only-ends (grouping-names (eval (first lexicons))))
         (remove-ends (rest lexicons)))
        (t (cons (first lexicons)(remove-ends (rest lexicons))))))

;;;;;
#| Calling (check-for-only-ends (fourbros[217]-68-34-56)) 
    check-for-only-ends returned nil|#
;;;;;

(defun CHECK-FOR-ONLY-ENDS (groupings)
  "Checks to see if the grouping contains only ending objects."
  (cond ((null groupings) t)
        ((equal (destination (eval (first groupings))) 'end)
         (check-for-only-ends (rest groupings)))
        (t ())))

;;;;;
#|  Calling (sequence-through-groupings improv-2[4220]-48-55) 
    sequence-through-groupings returned (improv-2[3154]-48-55
                                      improv-2[3155]-48-58-67 . . .|#
;;;;;

(defun SEQUENCE-THROUGH-GROUPINGS (choice)
  "Collects properly connected groupings."
  (cond ((equal choice 'end)())
        ((equal (destination (eval choice)) 'end)
         (list choice))
        (t (let ((new-choice (select choice)))
             (cons new-choice
                   (sequence-through-groupings (destination (eval new-choice))))))))

;;;;;
#| Calling (select improv-1[444]-37) 
    select returned forgray[80]-37|#
;;;;;

(defun SELECT (choice)
  "Selects randomly from objects in the same lexicon."
  (if (zerop (get-first-pitch (events (eval choice))))
    choice
    (choose-one (grouping-names (eval (lexicon (eval choice)))))))

;========================
;the reducing-ties series
;========================

;;;;;
#|  Calling (reduce-ties ((0 35 133 1 102) (0 55 133 1 105) . . .
     reduce-ties returned ((0 35 133 1 102) (0 55 133 1 105) . . .|#
;;;;;

(defun REDUCE-TIES (events)
  "Connects tied events and returns their joined composites."
  (loop until (null events)
        do (setf tied-events (if (equal (my-last (first events)) 'tie)
                              (get-complementary-events (first events)(rest events))))
        collect (if tied-events (progn (setf events (cons (first events)
                                                         (remove-all tied-events (rest events))))
                                      (butlast (add-them (first events) tied-events)))
                    (first events))
        do (setf events (rest events))))

;;;;;
#|Calling (add-them (1191 36 296 1 114 tie) ((1487 36 21 1 109))) 
   add-them returned (1191 36 317 1 114 tie)|#
;;;;;

(defun ADD-THEM (event events)
  "Creates one event from two based on tie."
  (append (firstn 2 event)
          (list (apply #'+ (mapcar #'third (cons event events))))
          (nthcdr 3 event)))

;;;;;
#|   Calling (get-complementary-events
            (1191 36 296 1 114 tie)
            ((1487 36 21 1 109) (1487 53 21 1 105 tie) (1508 53 25 1 105) . . .
     get-complementary-events returned ((1487 36 21 1 109))|#
;;;;;

(defun GET-COMPLEMENTARY-EVENTS (event events)
  "Finds the complementary event to one with a tie as its final element."
  (cond ((null events) nil)
        ((and 
          (equal (second event)(get-first-pitch events))
          (within-range (+ (first event)(third event))
                        (list (very-first events) t (very-first events)))
          (equal (my-last event) 'tie))
         (cons (first events)
               (get-complementary-events (first events) (rest events))))
        (t (get-complementary-events event (rest events)))))

;;;;;
#| Calling (within-range 1533 (62386 t 62388)) 
     within-range returned nil|#
;;;;;

(defun WITHIN-RANGE (number range)
  "Returns t if the number is within or equal to the boundaries of the range arg."
  (if (and (>= number (first range))
           (<= number (third range))) t))

;;;;;
#| Calling (remove-all ((3438 67 75 1 119))
                     ((3438 67 75 1 119) (3571 67 117 1 122) . . .
    remove-all returned ((3571 67 117 1 122) (3729 69 117 1 100)
                      (3862 36 392 1 95) (3879 67 154 1 98) . . .|#
;;;;;

(defun REMOVE-ALL (remove-events events)
  "A non-destructive way to remove a series of events from a list
          of events."
  (if (null remove-events) events
      (remove-all (rest remove-events)
                  (remove-it (first remove-events) events))))

;;;;;
#|  Calling (remove-it (3571 67 117 1 122)
                     ((3571 67 117 1 122) (3729 69 117 1 100) . . .
      remove-it returned ((3729 69 117 1 100) (3862 36 392 1 95)
                      (3879 67 154 1 98) (4167 64 112 1 104) . . .|#
;;;;;

(defun REMOVE-IT (event events)
  "Removes the first arg from the second arg once based on the first two elements."
  (cond ((null events)())
        ((and 
          (equal (first event)(very-first events))
          (equal (second event)(get-first-pitch events)))
         (rest events))
        (t (cons (first events)(remove-it event (rest events))))))

;;;;;
#|Calling (get-first-pitch
             ((3571 67 117 1 122) (3729 69 117 1 100) (3862 36 392 1 95) . . .
   get-first-pitch returned 67|#
;;;;;

(defun GET-FIRST-PITCH (events)
  "Returns the first pitch in events."
  (second (first events)))

;========================
;making the new composition playable
;========================

;;;;;
#| Calling (make-playable
           (improv-1[8117]-39-67 improv-1[9754]-67-60-38 . . .
    make-playable returned ((0 39 5 1 100) (0 67 16 1 114) (5 60 11 1 93) . . .|#
;;;;;

(defun MAKE-PLAYABLE (contiguous-groupings)
  "Makes the object groupings into playable events as well as recombining them with a different database timing sequence. "
  (reduce-ties 
   (sortcar #'< 
            (apply #'append 
                   (set-timings (mapcar #'first 
                                        (collect-groupings (eval (choose-one *database-names*))))    
                                (mapcar #'(lambda (x)(timing (eval x))) contiguous-groupings)
                                (mapcar #'(lambda (x)(events (eval x))) contiguous-groupings))))))

;;;;;
#|  Calling (set-timings ((2000 2005) (2005 2016) (2016 2021) (2021 2031) . . .
                         (((157925 39 54 1 100) (157925 67 75 1 114 tie))
                          ((158000 67 37 1 114) (158000 60 50 1 93)(158000 38 175 1 86 tie))
                          ((25575 38 8 1 86) . . .
     set-timings returned (((0 39 5 1 100) (0 67 5 1 114 tie)) . . .|#
;;;;;

(defun SET-TIMINGS (new-timings old-timings groupings &optional (current-time 0))
  "Resets the timings of the groupings so they will play consecutively."
  (if (or (null new-timings)(null groupings)(null (second (first new-timings))))()
      (cons (mapcar #'(lambda (x)(append (list current-time)
                                         (list (second x))
                                         (list (* (/ (third x)(- (second (first old-timings))(first (first old-timings))))
                                                  (- (second (first new-timings))(first (first new-timings)))))
                                         (nthcdr 3 x)))
                    (first groupings))
            (set-timings (rest new-timings)
                         (rest old-timings)
                         (rest groupings)
                         (+ current-time (- (second (first new-timings))(very-first new-timings)))))))

