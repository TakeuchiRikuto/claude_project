import 'package:flutter/material.dart';

enum CellState { empty, black, white }
enum GameMode { twoPlayer, vsBot }

class OthelloGameScreen extends StatefulWidget {
  const OthelloGameScreen({super.key});

  @override
  State<OthelloGameScreen> createState() => _OthelloGameScreenState();
}

class _OthelloGameScreenState extends State<OthelloGameScreen> {
  static const int boardSize = 8;
  List<List<CellState>> board = List.generate(
    boardSize,
    (i) => List.generate(boardSize, (j) => CellState.empty),
  );
  
  bool isBlackTurn = true;
  int blackScore = 2;
  int whiteScore = 2;
  bool gameOver = false;
  GameMode gameMode = GameMode.twoPlayer;
  bool isThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    board[3][3] = CellState.white;
    board[3][4] = CellState.black;
    board[4][3] = CellState.black;
    board[4][4] = CellState.white;
  }

  List<List<int>> _getValidMoves(CellState player) {
    List<List<int>> validMoves = [];
    
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == CellState.empty && _isValidMove(row, col, player)) {
          validMoves.add([row, col]);
        }
      }
    }
    return validMoves;
  }

  bool _isValidMove(int row, int col, CellState player) {
    if (board[row][col] != CellState.empty) return false;

    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      if (_checkDirection(row, col, direction[0], direction[1], player)) {
        return true;
      }
    }
    return false;
  }

  bool _checkDirection(int row, int col, int deltaRow, int deltaCol, CellState player) {
    CellState opponent = player == CellState.black ? CellState.white : CellState.black;
    int currentRow = row + deltaRow;
    int currentCol = col + deltaCol;
    bool foundOpponent = false;

    while (currentRow >= 0 && currentRow < boardSize && 
           currentCol >= 0 && currentCol < boardSize) {
      
      if (board[currentRow][currentCol] == CellState.empty) {
        return false;
      } else if (board[currentRow][currentCol] == opponent) {
        foundOpponent = true;
      } else if (board[currentRow][currentCol] == player) {
        return foundOpponent;
      }
      
      currentRow += deltaRow;
      currentCol += deltaCol;
    }
    return false;
  }

  void _makeMove(int row, int col) {
    if (!_isValidMove(row, col, isBlackTurn ? CellState.black : CellState.white)) {
      return;
    }

    CellState currentPlayer = isBlackTurn ? CellState.black : CellState.white;
    board[row][col] = currentPlayer;
    
    _flipPieces(row, col, currentPlayer);
    _updateScore();
    
    isBlackTurn = !isBlackTurn;
    
    _checkForNextMove();
  }

  void _checkForNextMove() {
    List<List<int>> nextValidMoves = _getValidMoves(
      isBlackTurn ? CellState.black : CellState.white
    );
    
    if (nextValidMoves.isEmpty) {
      isBlackTurn = !isBlackTurn;
      List<List<int>> currentValidMoves = _getValidMoves(
        isBlackTurn ? CellState.black : CellState.white
      );
      
      if (currentValidMoves.isEmpty) {
        _endGame();
        return;
      }
    }

    if (gameMode == GameMode.vsBot && !isBlackTurn && !gameOver) {
      _botMove();
    }
  }

  void _botMove() async {
    setState(() {
      isThinking = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    List<List<int>> validMoves = _getValidMoves(CellState.white);
    if (validMoves.isNotEmpty) {
      List<int> bestMove = _getBestMove(validMoves);
      
      CellState currentPlayer = CellState.white;
      board[bestMove[0]][bestMove[1]] = currentPlayer;
      
      _flipPieces(bestMove[0], bestMove[1], currentPlayer);
      _updateScore();
      
      isBlackTurn = !isBlackTurn;
    }

    setState(() {
      isThinking = false;
    });

    _checkForNextMove();
  }

  List<int> _getBestMove(List<List<int>> validMoves) {
    int bestScore = -1;
    List<int> bestMove = validMoves[0];

    final corners = [[0, 0], [0, 7], [7, 0], [7, 7]];
    final edges = [
      [0, 2], [0, 3], [0, 4], [0, 5],
      [2, 0], [3, 0], [4, 0], [5, 0],
      [7, 2], [7, 3], [7, 4], [7, 5],
      [2, 7], [3, 7], [4, 7], [5, 7]
    ];
    
    for (var move in validMoves) {
      int score = 0;
      
      if (corners.any((corner) => corner[0] == move[0] && corner[1] == move[1])) {
        score += 100;
      } else if (edges.any((edge) => edge[0] == move[0] && edge[1] == move[1])) {
        score += 20;
      }
      
      score += _countFlippedPieces(move[0], move[1], CellState.white);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int _countFlippedPieces(int row, int col, CellState player) {
    int count = 0;
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      if (_checkDirection(row, col, direction[0], direction[1], player)) {
        count += _countInDirection(row, col, direction[0], direction[1], player);
      }
    }
    return count;
  }

  int _countInDirection(int row, int col, int deltaRow, int deltaCol, CellState player) {
    CellState opponent = player == CellState.black ? CellState.white : CellState.black;
    int currentRow = row + deltaRow;
    int currentCol = col + deltaCol;
    int count = 0;

    while (currentRow >= 0 && currentRow < boardSize && 
           currentCol >= 0 && currentCol < boardSize &&
           board[currentRow][currentCol] == opponent) {
      count++;
      currentRow += deltaRow;
      currentCol += deltaCol;
    }
    return count;
  }

  void _flipPieces(int row, int col, CellState player) {
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      if (_checkDirection(row, col, direction[0], direction[1], player)) {
        _flipInDirection(row, col, direction[0], direction[1], player);
      }
    }
  }

  void _flipInDirection(int row, int col, int deltaRow, int deltaCol, CellState player) {
    CellState opponent = player == CellState.black ? CellState.white : CellState.black;
    int currentRow = row + deltaRow;
    int currentCol = col + deltaCol;

    while (currentRow >= 0 && currentRow < boardSize && 
           currentCol >= 0 && currentCol < boardSize &&
           board[currentRow][currentCol] == opponent) {
      
      board[currentRow][currentCol] = player;
      currentRow += deltaRow;
      currentCol += deltaCol;
    }
  }

  void _updateScore() {
    blackScore = 0;
    whiteScore = 0;
    
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == CellState.black) {
          blackScore++;
        } else if (board[row][col] == CellState.white) {
          whiteScore++;
        }
      }
    }
  }

  void _endGame() {
    setState(() {
      gameOver = true;
    });
  }

  void _resetGame() {
    setState(() {
      board = List.generate(
        boardSize,
        (i) => List.generate(boardSize, (j) => CellState.empty),
      );
      isBlackTurn = true;
      blackScore = 2;
      whiteScore = 2;
      gameOver = false;
      isThinking = false;
      _initializeBoard();
    });
  }

  void _changeGameMode(GameMode mode) {
    setState(() {
      gameMode = mode;
    });
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    List<List<int>> validMoves = _getValidMoves(
      isBlackTurn ? CellState.black : CellState.white
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Othello'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$blackScore',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      gameOver 
                        ? 'Game Over' 
                        : isThinking
                          ? 'Bot Thinking...'
                          : isBlackTurn 
                            ? (gameMode == GameMode.vsBot ? 'Your Turn' : 'Black Turn')
                            : (gameMode == GameMode.vsBot ? 'Bot Turn' : 'White Turn'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (gameOver)
                      Text(
                        blackScore > whiteScore 
                          ? (gameMode == GameMode.vsBot ? 'You Win!' : 'Black Wins!')
                          : whiteScore > blackScore 
                            ? (gameMode == GameMode.vsBot ? 'Bot Wins!' : 'White Wins!')
                            : 'Draw!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$whiteScore',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: boardSize,
                    ),
                    itemCount: boardSize * boardSize,
                    itemBuilder: (context, index) {
                      int row = index ~/ boardSize;
                      int col = index % boardSize;
                      bool isValidMove = validMoves.any((move) => move[0] == row && move[1] == col);
                      
                      return GestureDetector(
                        onTap: gameOver || isThinking || (gameMode == GameMode.vsBot && !isBlackTurn) ? null : () {
                          setState(() {
                            _makeMove(row, col);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            border: Border.all(color: Colors.black),
                          ),
                          child: Stack(
                            children: [
                              if (isValidMove && !gameOver)
                                Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (board[row][col] != CellState.empty)
                                Center(
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: board[row][col] == CellState.black 
                                        ? Colors.black 
                                        : Colors.white,
                                      shape: BoxShape.circle,
                                      border: board[row][col] == CellState.white
                                        ? Border.all(color: Colors.black, width: 1)
                                        : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: gameMode == GameMode.twoPlayer ? null : () => _changeGameMode(GameMode.twoPlayer),
                      child: const Text('2 Players'),
                    ),
                    ElevatedButton(
                      onPressed: gameMode == GameMode.vsBot ? null : () => _changeGameMode(GameMode.vsBot),
                      child: const Text('vs Bot'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _resetGame,
                  child: const Text('New Game'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}