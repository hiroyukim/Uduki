+{
    'full_text_search' => 0, 
    'DBI' => [
        "dbi:mysql:dbname=uduki",
        'root',
        '',
        +{
            RootClass => 'DBIx::Simple::Inject',
        }
    ],
};
