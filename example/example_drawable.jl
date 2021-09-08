import SimpleDraw as SD
import SimplePaint as SP

#####
##### example drawable
#####

mutable struct ExampleDrawable{I, C}
    background::SD.Background{C}
    hollow_cross::SD.HollowCross{I, C}
    line::SD.Line{I, C}
end

function SD.draw!(image::AbstractMatrix, drawable::ExampleDrawable)
    SD.draw!(image, drawable.background)
    SD.draw!(image, drawable.hollow_cross)
    SD.draw!(image, drawable.line)
    return nothing
end

#####
##### driver code
#####

height_image = 512
width_image = 512
image = zeros(UInt32, height_image, width_image)

background = SD.Background(0x00FFFFFF)
cross = SD.HollowCross(20, 30, 16, 0x00000000)
line = SD.Line(height_image ÷ 4, width_image ÷ 8, height_image - height_image ÷ 4 + 1, width_image - width_image ÷ 8 + 1, 0x00FF0000)
drawable = ExampleDrawable(background, cross, line)

path = Int[]

mode = SP.NAVIGATE

drawing_context = SP.DrawingContext(image, drawable, path, mode)

SP.start_session!(drawing_context)
