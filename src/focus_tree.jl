struct FocusTree{T}
    name::Symbol
    value::T
    path::Vector{Int}
    depth::Int
    is_in_path::Bool
    is_focused::Bool
end

#####
##### tree indexing
#####

function get_child(node::T, index) where {T}
    if Base.isiterable(T)
        return getindex(node, index)
    else
        return getfield(node, index)
    end
end

set_child!(node, index::Int, value) = setfield!(node, fieldname(typeof(node), index), value)
get_child_name(node, index::Int) = fieldname(typeof(node), index)

function get_current_node(root, path)
    if length(path) == 0
        return root
    else
        node = root

        for index in path
            node = get_child(node, index)
        end

        return node
    end
end

get_num_children(node) = nfields(node)

function get_num_siblings_current_node(root, path)
    if length(path) == 0
        return 1
    else
        return get_num_children(get_current_node(root, @view path[begin : end - 1]))
    end
end

#####
##### tree printing
#####

function AT.children(x::FocusTree)
    name = x.name
    value = x.value
    path = x.path
    depth = x.depth
    is_in_path = x.is_in_path
    is_focused = x.is_focused

    children = []
    for i in 1:get_num_children(value)
        child_name = get_child_name(value, i)
        child_value = get_child(value, i)
        child_path = path
        child_depth = depth + 1

        if is_in_path
            if checkbounds(Bool, path, child_depth)
                if i == path[child_depth]
                    child_is_in_path = true
                else
                    child_is_in_path = false
                end
            else
                child_is_in_path = false
            end

            if child_is_in_path && child_depth == length(path)
                child_is_focused = true
            else
                child_is_focused = false
            end
        else
            child_is_in_path = false
            child_is_focused = false
        end

        child = FocusTree(child_name, child_value, child_path, child_depth, child_is_in_path, child_is_focused)
        push!(children, child)
    end

    return children
end

function AT.printnode(io::IO, x::FocusTree)
    if x.is_focused
        print(io, "█")
    end
    print(io, x.name)

    if get_num_children(x.value) == 0
        print(io, " = ", repr(x.value))
    end

    return nothing
end

Base.show(io::IO, mime::MIME"text/plain", x::FocusTree) = AT.print_tree(io, x)

#####
##### tree navigation & update
#####

function move_in!(node, path)
    current_node = get_current_node(node, path)
    num_children_current_node = get_num_children(current_node)

    if num_children_current_node > 0
        push!(path, 1)
    end

    return nothing
end

function move_out!(node, path)
    if length(path) > 0
        pop!(path)
    end

    return nothing
end

function move_up!(node, path)
    if length(path) > 0
        num_siblings_current_node = get_num_siblings_current_node(node, path)
        path[end] = clamp(path[end] - 1, 1, num_siblings_current_node)
    end

    return nothing
end

function move_down!(node, path)
    if length(path) > 0
        num_siblings_current_node = get_num_siblings_current_node(node, path)
        path[end] = clamp(path[end] + 1, 1, num_siblings_current_node)
    end

    return nothing
end

increment(x) = x + one(x)
increment(x::Bool) = true

decrement(x) = x - one(x)
decrement(x::Bool) = false

function increment!(node, path)
    if length(path) > 0
        current_node = get_current_node(node, path)
        num_children_current_node = get_num_children(current_node)

        parent_node = get_current_node(node, @view path[begin : end - 1])
        if ismutable(parent_node)
            set_child!(parent_node, path[end], increment(current_node))
        end
    end

    return nothing
end

function decrement!(node, path)
    if length(path) > 0
        current_node = get_current_node(node, path)
        num_children_current_node = get_num_children(current_node)

        parent_node = get_current_node(node, @view path[begin : end - 1])
        if ismutable(parent_node)
            set_child!(parent_node, path[end], decrement(current_node))
        end
    end

    return nothing
end
