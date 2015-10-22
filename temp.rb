require "museum_provenance"

str = "Claude Oscar Monet [1840-1926], France, until October 30, 1905; purchased by Durand-Ruel Family, Paris, France, October 30, 1905, stock No. 8014 AL-212 [1]. Sam Salz, Inc., New York, NY, by 1967; purchased by Museum of Art, Carnegie Institute, Pittsburgh, PA, April 1967 [2]. \nNOTES:1. See document dated September 12, 1966 from Durand-Ruel prepared for Sam Salz in curatorial file. Photo No. 5393, 9077. 2. Updated by CGK December 2013."

timeline = MuseumProvenance::Provenance.extract str

puts timeline.to_json

