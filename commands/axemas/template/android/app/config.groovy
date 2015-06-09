// File: config.groovy
environments {
    dev  = "<?xml version='1.0' encoding='utf-8'?>\n" +
            "<resources>\n" +
            "<string name='base_url'>development_url</string>" +
            "</resources>"

    test  ="<?xml version='1.0' encoding='utf-8'?>\n" +
            "<resources>\n" +
            "<string name='base_url'>testing_url</string>\n" +
            "</resources>"

    prod  = "<?xml version='1.0' encoding='utf-8'?>\n" +
            "<resources>\n" +
            "<string name='base_url'>production_url</string>\n" +
            "</resources>"
}
