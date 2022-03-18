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
    
4. Run the following command to build the documentation.
   Note that this requires a temporary location for the built documentation;
   change `~/Desktop/apdocs` in all places below as necessary.

        swift package --allow-writing-to-directory ~/Desktop/apdocs \
            generate-documentation --target ArgumentParser --disable-indexing \
            --transform-for-static-hosting \
            --hosting-base-path swift-argument-parser \
            --output-path ~/Desktop/apdocs

5. Run the following command to copy the top-level redirect file into place.

        cp redirect.html ~/Desktop/apdocs/index.html
    
6. Check out the `gh-pages` branch, copy the files into place, and then push
   to the remote repository.

        git checkout gh-pages
        cp -R ~/Desktop/apdocs/* ./
        git add . && git commit -m "Update documentation"
        git push
