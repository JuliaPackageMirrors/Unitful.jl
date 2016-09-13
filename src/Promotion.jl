# ------ promote_op with dimensions and units ------

for op in (.+, .-, +, -)
    @eval function promote_op{S<:Dimensions,T<:Dimensions}(::typeof($op),
        ::Type{S}, ::Type{T})
        if S==T   # add or subtract same dimension, get same dimension
            x
        else
            error("Dimension mismatch.")
        end
    end
    @eval function promote_op{S<:DimensionedUnits,T<:DimensionedUnits}(
        ::typeof($op), ::Type{S}, ::Type{T})
        if dimension(S())==dimension(T())
            promote_type(S,T)
        else
            error("Dimension mismatch.")
        end
    end
end

function promote_op{S<:Unitlike,T<:Unitlike}(op, ::Type{S}, ::Type{T})
    typeof(op(S(), T()))
end

# ------ promote_op with quantities ------

# quantity, quantity
function promote_op{T1,D1,U1,T2,D2,U2}(op, x::Type{Quantity{T1,D1,U1}},
    y::Type{Quantity{T2,D2,U2}})
    # figuring out numeric type can be subtle if D1 == D2 but U1 != U2.
    # in particular, consider adding 1m + 1cm... the numtype is not Int.
    unittype = promote_op(op, U1, U2)
    numtype = if D1 == D2
        promote_type(T1, T2, typeof(convfact(U1(),U2())))
    else
        promote_type(T1, T2)
    end
    if unittype == Units{(), Dimensions{()}}
        numtype
    else
        dimtype = typeof(dimension(unittype()))
        Quantity{numtype, dimtype, unittype}
    end
end

# dim'd, quantity
promote_op{T2,D1,D2,U}(op, ::Type{DimensionedQuantity{D1}},
    ::Type{Quantity{T2,D2,U}}) = DimensionedQuantity{promote_op(op,D1,D2)}
promote_op{T2,D1,D2,U}(op, x::Type{Quantity{T2,D2,U}},
    y::Type{DimensionedQuantity{D1}}) = DimensionedQuantity{promote_op(op,D2,D1)}

# number, quantity
promote_op{R<:Number,S,D,U}(op, ::Type{R}, ::Type{Quantity{S,D,U}}) = Any
promote_op{R<:Number,S,D,U}(op, x::Type{Quantity{S,D,U}}, y::Type{R}) = Any

# dim'd, dim'd
promote_op{D1,D2}(op, ::Type{DimensionedQuantity{D1}},
    ::Type{DimensionedQuantity{D2}}) = DimensionedQuantity{promote_op(op,D1,D2)}

# dim'd, number
promote_op{D}(op, ::Type{DimensionedQuantity{D}}, ::Type{Number}) = Any
promote_op{D}(op, ::Type{Number}, ::Type{DimensionedQuantity{D}}) = Any


# ------ promote_op with units ------

# units, quantity
function promote_op{R<:Units,S,D,U}(op, ::Type{Quantity{S,D,U}}, ::Type{R})
    numtype = S
    unittype = typeof(op(U(), R()))
    if unittype == Units{(), Dimensions{()}}
        numtype
    else
        dimtype = typeof(dimension(unittype()))
        Quantity{numtype, dimtype, unittype}
    end
end
promote_op{R<:Units,S,D,U}(op, x::Type{R}, y::Type{Quantity{S,D,U}}) =
    promote_op(op, y, x)

# units, number
function promote_op{R<:Number,S<:Units}(op, x::Type{R}, y::Type{S})
    unittype = typeof(op(Units{(), Dimensions{()}}(), S()))
    if unittype == Units{(), Dimensions{()}}
        R
    else
        dimtype = typeof(dimension(unittype()))
        Quantity{x, dimtype, unittype}
    end
end
promote_op{R<:Number,S<:Units}(op, x::Type{S}, y::Type{R}) =
    promote_op(op, y, x)

# ------ promote_rule ------

# quantity, quantity (different dims)
promote_rule{S1,S2,D1,D2,U1,U2}(::Type{Quantity{S1,D1,U1}},
    ::Type{Quantity{S2,D2,U2}}) = Any

# quantity, quantity (same dims)
function promote_rule{S1,S2,D,U1,U2}(::Type{Quantity{S1,D,U1}},
    ::Type{Quantity{S2,D,U2}})

    numtype = promote_type(S1,S2,typeof(convfact(U1(),U2())))
    Quantity{numtype, D, promote_type(U1,U2)}
end

# quantity, quantity (same dims, same units)
promote_rule{S1,S2,D,U}(::Type{Quantity{S1,D,U}}, ::Type{Quantity{S2,D,U}}) =
    Quantity{promote_type(S1,S2),D,U}

# dim'd, quantity (different dims)
promote_rule{S2,D1,D2,U}(::Type{DimensionedQuantity{D1}},
    ::Type{Quantity{S2,D2,U}}) = Any

# dim'd, quantity (same dims)
promote_rule{S2,D,U}(::Type{DimensionedQuantity{D}},
    ::Type{Quantity{S2,D,U}}) = DimensionedQuantity{D}

# number, quantity
promote_rule{S,T<:Number,D,U}(::Type{Quantity{S,D,U}}, ::Type{T}) = Any

# dim'd, dim'd (different dims)
promote_rule{D1,D2}(::Type{DimensionedQuantity{D1}},
    ::Type{DimensionedQuantity{D2}}) = Any

# dim'd, dim'd (same dims)
promote_rule{D}(::Type{DimensionedQuantity{D}},
    ::Type{DimensionedQuantity{D}}) = DimensionedQuantity{D}

# dim'd, number
promote_rule{D,T<:Number}(::Type{DimensionedQuantity{D}}, ::Type{T}) = Any
