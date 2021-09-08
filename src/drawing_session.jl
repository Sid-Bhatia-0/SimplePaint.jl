const ESC = Char(27)

#####
##### modes
#####

@enum Mode NAVIGATE=1 TOGGLE=2

#####
##### drawing context
#####

mutable struct DrawingContext{I, D}
    image::I
    drawable::D
    path::Vector{Int}
    mode::Mode
end

#####
##### keybindings
#####

update!(drawing_context::DrawingContext, key) = update!(drawing_context, Val(key))

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_L})
    if drawing_context.mode == NAVIGATE
        move_in!(drawing_context.drawable, drawing_context.path)
    end

    return nothing
end

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_H})
    if drawing_context.mode == NAVIGATE
        move_out!(drawing_context.drawable, drawing_context.path)
    end

    return nothing
end

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_J})
    if drawing_context.mode == NAVIGATE
        move_down!(drawing_context.drawable, drawing_context.path)
    elseif drawing_context.mode == TOGGLE
        decrement!(drawing_context.drawable, drawing_context.path)
    end

    return nothing
end

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_K})
    if drawing_context.mode == NAVIGATE
        move_up!(drawing_context.drawable, drawing_context.path)
    elseif drawing_context.mode == TOGGLE
        increment!(drawing_context.drawable, drawing_context.path)
    end

    return nothing
end

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_ESCAPE})
    if drawing_context.mode == TOGGLE
        drawing_context.mode = NAVIGATE
    end

    return nothing
end

function update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_T})
    if drawing_context.mode == NAVIGATE
        drawing_context.mode = TOGGLE
    end

    return nothing
end

#####
##### drawing session
#####

function start_session!(drawing_context::DrawingContext)
    image = drawing_context.image
    drawable = drawing_context.drawable
    path = drawing_context.path

    height_image, width_image = size(image)
    frame_buffer = zeros(UInt32, width_image, height_image)

    window = MFB.mfb_open("SimplePaint", width_image, height_image)

    function keyboard_callback(window, key, mod, is_pressed)::Cvoid
        if is_pressed
            if key == MFB.KB_KEY_Q
                MFB.mfb_close(window)
                return nothing
            else
                update!(drawing_context, key)
                SD.draw!(image, drawable)
                copy_image_to_frame_buffer!(frame_buffer, image)
            end

            str = ""
            str = str * "$(ESC)[1J"
            str = str * "$(ESC)[H"
            str = str * repr(key)
            str = str * "\n"
            str = str * repr(path)
            str = str * "\n"
            str = str * repr(drawing_context.mode)
            str = str * "\n"
            focus_tree = FocusTree(:root, drawable, path, 0, true, length(path) == 0)
            str = str * repr("text/plain", focus_tree)
            print(str)
        end

        return nothing
    end

    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    while MFB.mfb_wait_sync(window)
        state = MFB.mfb_update(window, frame_buffer)

        if state != MFB.STATE_OK
            break;
        end
    end

    return nothing
end
