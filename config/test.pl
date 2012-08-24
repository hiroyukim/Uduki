+{
    'full_text_search' => 0, 
    'DBI' => [
        "dbi:mysql:dbname=test_uduki",
        'root',
        '',
        +{
            RootClass => 'DBIx::Simple::Inject',
        }
    ],
};
