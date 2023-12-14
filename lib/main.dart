import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:supabase/supabase.dart';
import 'package:equatable/equatable.dart';

void main() => runApp(MyApp());

class Score extends Equatable {
  final int id;
  final int score;

  Score({required this.id, required this.score});

  @override
  List<Object?> get props => [id, score];
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SupabaseClient client;
  List<Score> scores = [];

  List<int> sequence = [];
  List<int> userSequence = [];
  int score = 0;
  bool gameStarted = false;
  bool showUpperImages = true;
  bool showLowerButtons = false;
  List<String> imagePaths = [
    'assets/images/rayo.jpg',
    'assets/images/amarillo.jpg',
    'assets/images/bugg.jpg',
    'assets/images/coche.jpg',
    'assets/images/rojo.png',
    'assets/images/dacia.jpg',
  ];

  @override
  void initState() {
    super.initState();

    client = SupabaseClient(
      'https://qkxjwgjirgthdmspmlsw.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFreGp3Z2ppcmd0aGRtc3BtbHN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDI1MDU5MjgsImV4cCI6MjAxODA4MTkyOH0.a3QXY9q8faayC7oViDf79Y_A0iYPlCexawD2vg8McnE',
    );

    fetchScores();
  }

  Future<void> fetchScores() async {
    try {
      final response = await client.from('scores').select().execute();

      final List<dynamic>? data = response.data;
      if (data != null) {
        setState(() {
          scores = data.map((e) => Score(id: e['id'], score: e['score'])).toList();
        });
      }
    } catch (e) {
      print('Error fetching scores: $e');
    }
  }

  Future<void> saveScore() async {
    try {
      final response = await client.from('scores').upsert([
        {'score': score},
      ]).execute();

      fetchScores();
    } catch (e) {
      print('Error saving score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    scores.sort((a, b) => b.score.compareTo(a.score));
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Score: $score'),
            if (gameStarted)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: sequence.map((index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Visibility(
                      visible: showUpperImages,
                      child: Image.asset(
                        imagePaths[index],
                        width: getScreenWidth(context) * 0.08,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (!gameStarted)
              ElevatedButton(
                onPressed: () => startGame(),
                child: Text('Entrar Al juego'),
              ),
            if (gameStarted)
              ElevatedButton(
                onPressed: () {
                  if (showLowerButtons) {
                    startGame();
                    showUpperImages = !showUpperImages;
                    showLowerButtons = !showLowerButtons;
                  }
                  setState(() {
                    showUpperImages = !showUpperImages;
                    showLowerButtons = !showLowerButtons;
                  });
                },
                child: Text(showUpperImages ? 'Play' : 'Te Rindes'),
              ),
            if (gameStarted && showLowerButtons)
              ElevatedButton(
                onPressed: () => checkSequence(),
                child: Text('Pantalla Final'),
              ),
            if (gameStarted && showLowerButtons)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imagePaths.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: ElevatedButton(
                      onPressed: () => onImageClicked(index),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // Fondo blanco
                        elevation: 0, // Sin sombra
                      ),
                      child: Image.asset(
                        imagePaths[index],
                        width: getScreenWidth(context) * 0.05,
                      ),
                    ),
                  );
                }),
              ),
            if (scores.isNotEmpty)
              Container(
                padding: EdgeInsets.all(7.0),
                margin: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black), // Puedes ajustar el color y grosor del borde según tus preferencias
                  borderRadius: BorderRadius.circular(10.0), // Puedes ajustar el radio de las esquinas según tus preferencias
                ),
                child: Column(
                  children: [
                    Text('TABLA DE PUNTUACIONES'),
                    Column(
                      children: scores.map((s) => Text('${s.score}')).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void startGame() {
    setState(() {
      gameStarted = true;
      score = 0;
      sequence = generateRandomSequence();
      userSequence = [];
      playSequence();
      showUpperImages = true;
      showLowerButtons = false;
    });
  }

  List<int> generateRandomSequence() {
    List<int> randomSequence = List.generate(6, (index) => index);
    randomSequence.shuffle();
    return randomSequence;
  }

  double getScreenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
  }

  void playSequence() {
    int index = 0;
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (index < sequence.length) {
        print('Show image: ${imagePaths[sequence[index]]}');
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void checkSequence() {
    if (listEquals(sequence, userSequence)) {
      setState(() {
        score++;
        userSequence = [];
        sequence = generateRandomSequence();
        playSequence();
        saveScore();
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Game Over'),
            content: Text('Your score is $score'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  saveScore();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      setState(() {
        gameStarted = false;
      });
    }
  }

  void onImageClicked(int index) {
    if (gameStarted) {
      if (userSequence.length < sequence.length && index == sequence[userSequence.length]) {
        setState(() {
          userSequence.add(index);
          if (userSequence.length == sequence.length) {
            score++;
            showUpperImages = true;
            showLowerButtons = false;
            userSequence = [];
            sequence = generateRandomSequence();
            playSequence();
          }
        });
      } else {
        checkSequence();
      }
    }
  }
}