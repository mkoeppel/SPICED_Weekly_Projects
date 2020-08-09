# import necessary libraries for html-text-parsing
import requests
from bs4 import BeautifulSoup
import os
from pathlib import Path
import pandas as pd
import random

# for nlp models and predictions
from sklearn.feature_extraction.text import CountVectorizer, TfidfTransformer
from sklearn.naive_bayes import MultinomialNB # for count data, which we have of words in text
from imblearn.pipeline import make_pipeline
from imblearn.under_sampling import RandomUnderSampler

# neccessary for wordcloud
import numpy as np
from matplotlib import pyplot as plt
import wordcloud as wc
from wordcloud import STOPWORDS

def artists_collection():
    '''
    start the pipeline by entering some artists

    Params:
        input: program will ask for artists until 'done' is typed
        output: a artists_list, a list of the given artists
    '''

    messages = ['Excellent choice!',
    'Wow, did you the that life show?',
    'Very good one indeed!',
    'Really?',
    'Yeah, always great!',
    'Are you serious?',
    'Oh, I like them too.',
    'Not so sure about that one.'
    ]

    print("""Hello there!
    Tell me, what's your most favorite musician?
    (type 'exit' to end and 'done' to proceed)""")

    artists_list = []
    artist = ''
    while True:
        artist = input()
        if artist == 'done':
            break
        if artist == 'exit':
            exit()
        else:
            print(messages[random.randint(0, len(messages) - 1)] + ' Lets pick another one.')
            artists_list.append(artist)
    return artists_list

artists_list = artists_collection()

def artist_to_song_list(artists_list): # limit is tht to the first 20 songs for performance reasons
    '''
    produces a folder with html-song texts of a list of artists from lyrics.com

    Params:
        input: a list of artists
        output: a datframe with all the artists, their songs and links to the lyrics-webpages
    '''
    title = []
    link = []
    label = []

    for i in artists_list:
        url = f'https://www.lyrics.com/artist/{i}/'
        artist_response = requests.get(url)
        artist_html = artist_response.text
        artist_soup = BeautifulSoup(artist_html, features="lxml")

        for tag in artist_soup.body.find_all(class_ = 'tal qx', limit = 20):
            title.append(tag.get_text())
            link.append(tag.find('a')['href'])
            label.append(i)
    songs = {'label': label, 'title' : title, 'link': link }
    artist_songs = pd.DataFrame(songs)
    return artist_songs

artist_songs = artist_to_song_list(artists_list)

def get_song_lyrics(artist_songs):
    '''
    extracting all lyrics from the above derived song_list

    Params:
        input: the output of artist_to_song_list and the corresponding artist
        output: a vector of the labels and a list of files, each including the lyrics of one song
    '''

    for index, row in artist_songs.iterrows():
        Path(row['label']).mkdir(parents=True, exist_ok=True)
        with open(os.path.join(row['label'],(row['title'])+'.txt'), 'w') as file:
            url = 'https://www.lyrics.com'+str(row['link'])
            request = requests.get(url)
            file.write(request.text)

#get_song_lyrics(artist_songs)

def word_cloud_corpi(artists_list):
    '''
    get wordcloud-pictures for individual artists
    '''
    for i in artists_list:
        lyrics_corpus = []
        for fn in os.listdir(f'{i}'):
            with open(f'{i}/'+fn) as file:
                text = file.read()
                text_soup = BeautifulSoup(text, features='lxml')
                for tag in text_soup.body.find_all(id = 'lyric-body-text'):
                    lyrics_corpus.append(tag.get_text())
        lyrics_list = ' '.join(lyrics_corpus)


        cloud = wc.WordCloud(background_color="white",
                max_words=100,
                stopwords = STOPWORDS,
                collocations=False,  # calculates frequencies
                contour_color='steelblue').generate(lyrics_list)
                # stop words are removed!

        plt.figure(figsize = (6,3   ))
        plt.title(f'{i} most favorite words')
        plt.imshow(cloud, interpolation='bilinear')
        plt.savefig(f'{i}_cloud.png')
        plt.ioff()
        plt.show(block = False)


word_cloud_corpi(artists_list)

def build_lyrics_corpus(artists_list):
    '''
    takes a list of artists and their lyrics-files and assembles a lyrics_corpus

    Params:
        input: a list of artists and a path to the directories with their song-lyrics as html
        output: a lyrics_corpus in lower case to be further processed also including the artist-names as labels
    '''
    lyrics_corpus = []
    labels = []
    for i in artists_list:
        for fn in os.listdir(f'{i}'):
            with open(f'{i}/'+fn) as file:
                text = file.read()
                text_soup = BeautifulSoup(text, features='lxml')
                for tag in text_soup.body.find_all(id = 'lyric-body-text'):
                    lyrics_corpus.append(tag.get_text())
            labels.append(f'{i}')
    lyrics_corpus = [item.lower() for item in lyrics_corpus]
    return labels, lyrics_corpus


Lyrics_corpus = build_lyrics_corpus(artists_list)
LC = pd.DataFrame(Lyrics_corpus)
lc = LC.transpose()
lc = lc.replace('\n',' ', regex=True)
corpus = lc[1]
label = lc[0]

def train_model(text, labels):
    """
    Trains a scikit-learn classification model on text.

    Parameters
    ----------
    text : list
    labels : list

    Returns
    -------
    model : Trained scikit-learn model.

    """
    cv = CountVectorizer(stop_words = 'english')
    tf = TfidfTransformer()
    rus = RandomUnderSampler(random_state=10, sampling_strategy= 'auto')

    mnb = MultinomialNB(alpha = 1)

    model = make_pipeline(cv, tf, rus, mnb)
    model.fit(text, labels)

    return model

def predict(model, new_text):
    """
    Takes the pre-trained model pipeline and predicts new artist based on unseen text.

    Parameters
    ----------
    model : Trained scikit-learn model.
    new_text : list

    Returns
    ---------
    prediction : str

    """

model = train_model(corpus, label)

print("""What about some new lyrics? (type 'exit' to end)""")
new_text = ''
while True:
    new_text = input()
    if new_text == 'exit':
        exit()
    else:
        new_text = [new_text]
        prediction = model.predict(new_text)
        print('Here is your prediction:')
        print(prediction)

        print('Got any more?')
