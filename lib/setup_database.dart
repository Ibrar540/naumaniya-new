import 'package:postgres/postgres.dart';

Future<void> setupNeonDatabase() async {
  print('🔄 Connecting to Neon database...');
  
  final connection = await Connection.open(
    Endpoint(
      host: 'ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_eId5vglW0kKO',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );

  print('✅ Connected! Creating tables...\n');

  try {
    // 1. Students Table
    print('Creating students table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS students (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          father_name VARCHAR(255),
          mobile_no BIGINT,
          class VARCHAR(100),
          fee NUMERIC(10, 2),
          status VARCHAR(50) DEFAULT 'active',
          admission_date DATE,
          struck_off_date DATE,
          graduation_date DATE,
          image TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Students table created');

    // 2. Teachers Table
    print('Creating teachers table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          mobile_no BIGINT,
          starting_date DATE,
          status VARCHAR(50) DEFAULT 'Active',
          leaving_date DATE,
          salary NUMERIC(10, 2) DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Teachers table created');

    // 3. Sections Table
    print('Creating sections table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS sections (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          institution VARCHAR(50) NOT NULL,
          type VARCHAR(50) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Sections table created');

    // 4. Classes Table
    print('Creating classes table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS classes (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL UNIQUE,
          status VARCHAR(50) DEFAULT 'active',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Classes table created');

    // 5. Madrasa Income Table
    print('Creating madrasa_income table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS madrasa_income (
          id SERIAL PRIMARY KEY,
          description TEXT NOT NULL,
          rs NUMERIC(10, 2) NOT NULL,
          date DATE NOT NULL,
          section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Madrasa income table created');

    // 6. Madrasa Expenditure Table
    print('Creating madrasa_expenditure table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS madrasa_expenditure (
          id SERIAL PRIMARY KEY,
          description TEXT NOT NULL,
          rs NUMERIC(10, 2) NOT NULL,
          date DATE NOT NULL,
          section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Madrasa expenditure table created');

    // 7. Masjid Income Table
    print('Creating masjid_income table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS masjid_income (
          id SERIAL PRIMARY KEY,
          description TEXT NOT NULL,
          rs NUMERIC(10, 2) NOT NULL,
          date DATE NOT NULL,
          section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Masjid income table created');

    // 8. Masjid Expenditure Table
    print('Creating masjid_expenditure table...');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS masjid_expenditure (
          id SERIAL PRIMARY KEY,
          description TEXT NOT NULL,
          rs NUMERIC(10, 2) NOT NULL,
          date DATE NOT NULL,
          section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('✅ Masjid expenditure table created');

    // Create indexes
    print('\nCreating indexes...');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_students_class ON students(class)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_students_status ON students(status)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_students_admission_date ON students(admission_date)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_teachers_status ON teachers(status)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_teachers_starting_date ON teachers(starting_date)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_sections_institution_type ON sections(institution, type)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_madrasa_income_section ON madrasa_income(section_id)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_madrasa_income_date ON madrasa_income(date)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_section ON madrasa_expenditure(section_id)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_date ON madrasa_expenditure(date)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_masjid_income_section ON masjid_income(section_id)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_masjid_income_date ON masjid_income(date)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_section ON masjid_expenditure(section_id)');
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_date ON masjid_expenditure(date)');
    print('✅ Indexes created');

    print('\n🎉 All tables created successfully!');
    print('\nNext steps:');
    print('1. Export data from your old database as CSV files');
    print('2. Import CSV files to Neon');
    print('3. Run your Flutter app');

  } catch (e) {
    print('❌ Error creating tables: $e');
  } finally {
    await connection.close();
    print('\n✅ Connection closed');
  }
}

void main() async {
  await setupNeonDatabase();
}
