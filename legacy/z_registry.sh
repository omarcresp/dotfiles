# .folders is a file that contains the list of parent folders, one per line
# parent_folders should be a list to be used in a for loop
parent_folders=`cat ~/.folders | tr '\n' ' '`

for folder in $parent_folders
do
    # ls the folder
    path=`echo "$HOME/$folder"`

    # list of subfolders
    subfolders=`ls $path | tr '\n' ' '`

    # for each subfolder, create a registry
    for subfolder in $subfolders
    do
        # create a registry
        subpath=`echo "$path/$subfolder"`

        # if the registry already exists, skip
        zoxide query $subpath > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            continue
        fi

        zoxide add $subpath
    done
done
