<?php

$driver     = getenv('LIMESURVEY_DB_TYPE'); // 'mysql' or 'pgsql'
$database   = getenv('LIMESURVEY_DB_NAME');
$username   = getenv('LIMESURVEY_DB_USER');
$password   = getenv('LIMESURVEY_DB_PASSWORD');
$host       = getenv('LIMESURVEY_DB_HOST');
$port       = getenv('LIMESURVEY_DB_PORT ');

$numTables = 0;

echo "------------------------------------------------\n";
echo "Database Connection Test\n";
echo "PHP ".PHP_VERSION."\n";
echo "DB driver: $driver\n";
echo "------------------------------------------------\n";

if ($driver === 'mysql') {
    $connection = mysqli_connect($host, $username, $password, null, $port)
        or die("🚫 Unable to Connect to '$host'.\n\n");
    mysqli_select_db($connection, $database)
        or die("🚫 Connected but could not open db '$database'.\n\n");
    $result = mysqli_query($connection, "SHOW TABLES FROM $database");

    if ($result === false) {
        die("🚫 Couldn’t query '$database'.\n\n");
    }

    while($table = mysqli_fetch_array($result)) {
        $numTables++;
        //echo $table[0]."\n";
    }
} elseif ($driver === 'pgsql') {
    $connection = pg_connect("host=$host dbname=$database user=$username password=$password port=$port")
        or die("🚫 Unable to Connect to '$host'.\n\n");
    $result = pg_query(
        $connection,
        "SELECT table_schema || '.' || table_name
               FROM information_schema.tables
               WHERE table_type = 'BASE TABLE'
               AND table_name like 'lime_%'
               AND table_schema NOT IN ('pg_catalog', 'information_schema');
        "
    );

    if ($result === false) {
        die("🚫 Couldn’t query '$database'.\n\n");
    }

    while($table = pg_fetch_array($result)) {
        $numTables++;
        //echo $table[0]."\n";
    }
} else {
    die("⛔ Invalid driver `$driver`; must be `mysql` or `pgsql`.\n\n");
}

if (!$numTables) {
    echo "🤷‍️ Connected but no tables found.\n\n";
    exit(1);
} else {
    echo "👍 Connected and found LimeSurvey (lime_%) tables.\n\n";
    exit(0);
}