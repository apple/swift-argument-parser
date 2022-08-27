# Documentation Generation

This branch has a slightly different configuration than `main` or the release
branches, in order to support generating API documentation.

To generate a new set of documentation, follow these steps:

1. Merge the latest changes into this branch.

2. Check that you're using a Swift toolchain that is at least version 5.6.

3. To preview the updated documentation, run the following command:

        swift package --disable-sandbox preview-documentation \
            --target ArgumentParser
        
   You can view the documentation at:
      
        http://localhost:8000/documentation/argumentparser
    
4. Run the following command to build the documentation and push it to the `gh-pages` site:

        Scripts/generate-docs.sh
