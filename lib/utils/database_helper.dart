import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "lora_packets_local.db";
  static final _databaseVersion = 1;
  static final table = 'CEMIG_MTCMG';
  // torna esta classe singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  // tem somente uma referência ao banco de dados
  static Database _database;

  Future<Database> get database async {
    // if (_database != null) return _database;//uncomment if only needed to fetch the first time
    // instancia o db na primeira vez que for acessado
    _database = await _initDatabase();
    return _database;
  }

  // abre o banco de dados e o cria se ele não existir
  _initDatabase() async {
    // Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String dir = (await getExternalStorageDirectory()).path;
    String path = join(dir, _databaseName);
    print("Path to the dB: $path");
    return await openDatabase(path, version: _databaseVersion);
  }

  // Todas as linhas são retornadas como uma lista de mapas, onde cada mapa é
  // uma lista de valores-chave de colunas.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    final result = await db.query(table);
    return result;
  }

  Future<List<Map<String, dynamic>>> varmsquery() async {
    Database db = await instance.database;
    final result = await db.query(table, columns: ['time', 'VArms']);
    return result;
  }
}
