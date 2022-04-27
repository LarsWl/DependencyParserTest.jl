module DependencyTree
  using AbstractTrees

  export TreeNode

  mutable struct TreeNode
    token::String
    children::Vector{TreeNode}
    parent::TreeNode
    parent_label::String

    TreeNode(token::String) = new(token, Vector{TreeNode}())
    TreeNode(token::String, parent::TreeNode, parent_label::String) = (node = new(token, Vector{TreeNode}(), parent, parent_label); add_child(parent, node); node)
  end

  function AbstractTrees.children(node::TreeNode)
    node.children
  end

  function add_child(parent::TreeNode, child::TreeNode)
    push!(parent.children, child)
  end

  function find_node(root::TreeNode, token::String)
    if root.token == token
      return root
    end

    for node in root.children
      result = find_node(node, token)
      if result === nothing
        continue
      end

      return result
    end

    nothing
  end
end
