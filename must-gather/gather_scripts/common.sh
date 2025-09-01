

KUBECTL=${KUBECTL:-"kubectl"}

outfile="${output_dir}/gather_log.txt"

function gather_log() {
    local msg=$1

    if [[ ${log_to_stdout:-} ]] ; then
        printf "$msg\n"
    else
        printf "$msg\n" >> "$outfile"
    fi
}

# a go-template for display of secrets resources without confidential values
GATHER_SECRET_TEMPLATE='Secret {{.metadata.name}}{{println}}uid: {{.metadata.uid}}{{println}}ownerReferences:{{println}}  {{.metadata.ownerReferences}}{{println}}labels: {{println}}  {{.metadata.labels}}{{println}}data:{{println}}{{range $k, $v := .data}}  {{$k}}: {{if or (eq $k "ca.crt") (eq $k "tls.crt") }}{{$v|base64decode}}{{else}}<redacted>{{end}}{{println}}{{end}}'

# Extract a field from a k8s resource.
# Logs to outfile on error (missing resource or missing property).
# Returns the default value in case of error, or the property value if found.
function extract_property() {
    local type=$1       # type of the K8S resource
    local name=$2       # name of K8S resource
    local namespace=$3  # namespace of K8S resource
    local property=$4   # 'jsonpath' of the property to extract
    local prop_desc=$5  # description of the property to extract (for error messages when )
    local default=$6    # default value to return on error

    local extracted=$("$KUBECTL" get -n "$namespace" $type "$name" -o jsonpath={$property})
    if [[ -n "$extracted" ]] ; then
       printf "Detected explicit $prop_desc '$extracted' in $type resource '$name'.\n\n" >>"$outfile"
    else
       extracted=$default
       printf "No explicit $prop_desc in $type resource '$name', defaulting to $default.\n\n" >>"$outfile"
    fi
    printf "$extracted"
}

function dump_pods() {
    local namespace=$1
    local pod_list=$2

    local pods=( $pod_list )
    local pods_dir="namespaces/${namespace}/pods"

    for pod in "${pods[@]}" ; do
        pod_dir="$pods_dir/$pod"
        mkdir -p "$pod_dir"
        "$KUBECTL" get pod -n "$namespace" "$pod" -o yaml >"$pod_dir/pod.yaml" 2>&1
        printf "  - $pod: yaml resource dumped in $pod_dir/pod.yaml\n"
        "$KUBECTL" describe pod -n "$namespace" "$pod" >"$pod_dir/describe.txt" 2>&1
        printf "  - $pod: resource description dumped in $pod_dir/describe.txt\n"

        for pod_container in $("$KUBECTL" get pod -n "$namespace" "$pod" -o template='{{range .spec.initContainers}}{{.name}}{{println}}{{end}}') ; do
            mkdir -p "$pod_dir/initContainer_logs"
            log_file="$pod_dir/initContainer_logs/${pod_container}.log"
            "$KUBECTL" logs -n "$namespace" "$pod" -c "$pod_container" >"$log_file"  2>&1
            printf "  - $pod: logs of init container '$pod_container' dumped in $log_file\n"
        done

        for pod_container in $("$KUBECTL" get pod -n "$namespace" "$pod" -o template='{{range .spec.containers}}{{.name}}{{println}}{{end}}') ; do
            mkdir -p "$pod_dir/container_logs"
            log_file="$pod_dir/container_logs/${pod_container}.log"
            "$KUBECTL" logs -n "$namespace" "$pod" -c "$pod_container" >"$log_file"  2>&1
            printf "  - $pod: logs of container '$pod_container' dumped in $log_file\n"
        done
    done
}

function dump_pods_in_failure() {
    local namespace=$1

    local failing_pods=($("$KUBECTL" get pods -n "$namespace" | grep -Ev '1/1|2/2|3/3|4/4|5/5|6/6|7/7|8/8|Running|Completed|Succeeded' | tail -n +2 |cut -f1 -d' '))

    if [[ ${#failing_pods[@]} -gt 0 ]] ; then
        printf "\nDetected ${#failing_pods[@]} not completed or not ready pods.  Dumping description and logs of those...\n"
        dump_pods "$namespace" "${failing_pods[*]}"
    else
        printf "All pods look healthy.\n"
    fi
}


function get_k8s_resource() {
    local kind=$1
    local namespace=$2
    local name=$3

    local res_dir="$output_dir/namespaces/$namespace"
    mkdir -p "$res_dir"
    local res_file="$res_dir/$kind:$name.yaml"
    gather_log "Fetching $kind $namespace/$name."

    if [[ $kind = "secret" || $kind = "Secret" ]] ; then
        "$KUBECTL" get secret -n "$namespace" "$name" -o template="$GATHER_SECRET_TEMPLATE"  > "$res_file" 2>>"$outfile"
    else
        "$KUBECTL" get "$kind" -n "$namespace" "$name" -o yaml > "$res_file" 2>>"$outfile"
    fi
}

function get_all_k8s_resource() {
    local kind=$1
    local namespace=$2

    local res_dir="$output_dir/namespaces/$namespace"
    mkdir -p "$res_dir"
    "$KUBECTL" get "$kind" -n "$namespace" > "$res_dir/$kind:LIST.txt" 2>>"$outfile"
    gather_log "Fetching all $kind from $namespace."

    if [[ $kind = "secret" || $kind = "Secret" ]] ; then
        for name in $("$KUBECTL" get -n "$namespace" --no-headers "$kind" | cut -f1 -d' ') ; do
            get_k8s_resource "$kind" "$namespace" "$name"
        done
    else
        local res_file="$res_dir/$kind:ALL.yaml"
        "$KUBECTL" get "$kind" -n "$namespace" -o yaml > "$res_file" 2>>"$outfile"
    fi
}

function get_all_pod_logs() {
    local namespace=$1

    for pod in $("$KUBECTL" get -n "$namespace" --no-headers pods | cut -f1 -d' ') ; do
        local pod_dir="$output_dir/namespaces/$namespace/pod:$pod"
        mkdir -p "$pod_dir"

        gather_log "Fetching description of pod $namespace/$pod."
        "$KUBECTL" describe pod -n "$namespace" "$pod" >"$pod_dir/describe.txt" 2>>"$outfile"
        
        for pod_container in $("$KUBECTL" get pod -n "$namespace" "$pod" -o template='{{range .spec.initContainers}}{{.name}}{{println}}{{end}}') ; do
            mkdir -p "$pod_dir/initContainer_logs"
            log_file="$pod_dir/initContainer_logs/${pod_container}.log"
            gather_log "Fetching log of initcontainer $pod_container of pod $namespace/$pod."
            # no --since on init container, because they probably ran long ago
            "$KUBECTL" logs -n "$namespace" "$pod" -c "$pod_container" >"$log_file" 2>>"$outfile"
        done

        for pod_container in $("$KUBECTL" get pod -n "$namespace" "$pod" -o template='{{range .spec.containers}}{{.name}}{{println}}{{end}}') ; do
            mkdir -p "$pod_dir/container_logs"
            log_file="$pod_dir/container_logs/${pod_container}.log"
            gather_log "Fetching log of container $pod_container of pod $namespace/$pod."
            "$KUBECTL" logs -n "$namespace" --since "$since" "$pod" -c "$pod_container" >"$log_file" 2>>"$outfile"
        done
    done
}

