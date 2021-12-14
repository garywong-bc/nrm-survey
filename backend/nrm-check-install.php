<?php

$driver     = getenv('DB_TYPE'); // 'mysql' or 'pgsql'
$database   = getenv('POSTGRESQL_DB_NAME');
$username   = getenv('POSTGRESQL_USERNAME');
$password   = getenv('POSTGRESQL_PASSWORD');
$host       = getenv('POSTGRESQL_DB_HOST');
$port       = getenv('POSTGRESQL_PORT ');

$numTables = 0;

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

if (!$numTables) { // Connected but no tables found
    exit("NOINSTALL");
} else { // Connected and found LimeSurvey (lime_%) tables
    exit("INSTALL");
}