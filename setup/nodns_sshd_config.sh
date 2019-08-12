#!/bin/bash
FILE=/etc/ssh/sshd_config
echo "$0 opening '$FILE'"
if [[ ! -f $FILE ]]; then
    echo "Error '$FILE' is not a file" >&2
    exit 1
fi
if [[ ! -r $FILE ]]; then
    echo "Error '$FILE' is not readable" >&2
    exit 1 
fi
if [[ ! -w $FILE ]]; then
    echo "Error '$FILE' is not writtable" >&2
    exit 1 
fi
cat $FILE | grep -Pi '^UseDNS yes\s*#?' > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "'UseDNS yes' already set in '$FILE', disable it"
    sed -i -re 's/^(UseDNS yes\s*#?)/#\1/i' $FILE > /dev/null 2>&1
    cat $FILE | grep -Pi '^UseDNS yes\s*#?' > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "Error could not modify '$FILE'" >&2
        exit 1
    fi
fi
cat $FILE | grep -Pi '^UseDNS no\s*#?' > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "'UseDNS no' already set in '$FILE'"
    exit 0
else
    echo "'UseDNS no' does not set in '$FILE'"
    cat $FILE | grep -Pi '^\s*#\s*UseDNS no\s*#?' > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "Found '#UseDNS no' uncommenting it"
        sed -i -re 's/^\s*#\s*(UseDNS no\s*#?)/\1/i' $FILE > /dev/null 2>&1
        cat $FILE | grep -Pi '^\s*#\s*UseDNS no\s*#?' > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "Error could not modify '$FILE'" >&2
            exit 1
        fi
    else
        cat $FILE | grep -Pi '^\s*#\s*UseDNS yes' > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "Replace '#UseDNS yes' to 'UseDNS no'"
            sed -i -re 's/^\s*#\s*UseDNS yes/UseDNS no/i' $FILE
            cat $FILE | grep -Pi '^\s*#\s*UseDNS no\s*#?' > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo "Error could not modify '$FILE'" >&2
                exit 1
            fi
        else
            echo "Appending 'UseDNS no'"
            echo "UseDNS no" >> $FILE
            cat $FILE | grep -Pi '^\s*#\s*UseDNS no\s*#?' > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo "Error could not modify '$FILE'" >&2
                exit 1
            fi
        fi
    fi
fi

