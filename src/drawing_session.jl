#####
##### drawing context
#####

struct DrawingContext{I, D}
    image::I
    drawable::D
    path::Vector{Int}
end

#####
##### keybindings
#####

update!(drawing_context::DrawingContext, key) = update!(drawing_context, Val(key))
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_L}) = move_in!(drawing_context.drawable, drawing_context.path)
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_H}) = move_out!(drawing_context.drawable, drawing_context.path)
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_K}) = move_up!(drawing_context.drawable, drawing_context.path)
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_J}) = move_down!(drawing_context.drawable, drawing_context.path)
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_UP}) = increment!(drawing_context.drawable, drawing_context.path)
update!(drawing_context::DrawingContext, key::Val{MFB.KB_KEY_DOWN}) = decrement!(drawing_context.drawable, drawing_context.path)

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
            println("*******************************")
            println(key)
            if key == MFB.KB_KEY_Q
                MFB.mfb_close(window)
                return nothing
            else
                update!(drawing_context, key)
                SD.draw!(image, drawable)
                copy_image_to_frame_buffer!(frame_buffer, image)
            end

            @show path
            AT.print_tree(stdout, FocusTree(:root, drawable, path, 0, true, length(path) == 0))
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
